//
//  File.swift
//
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation
import Combine

public actor PiggyBacker<HashKey: Hashable, P: Publisher, ID> {
    
    private(set) var inFlights: [HashKey: InFlight] = [:]
    
    public init() { }
    
    @discardableResult
    public func dispatch(_ key: HashKey, id: inout ID?, createPublisher: (HashKey) -> (id: ID, publisher: P)) async throws -> P.Output {
        defer { Task { await cleanCompletedInFlights() } }
        
        if let existing = inFlights[key], !existing.didComplete {
            id = existing.id
            return try await existing.attach()
        } else {
            let (newID, publisher) = createPublisher(key)
            id = newID
            let inflight = InFlight(id: newID, publisher: publisher)
            inFlights[key] = inflight
            return try await inflight.attach()
        }
    }
    
    @discardableResult
    public func dispatch(_ key: HashKey, createPublisher: (HashKey) -> P) async throws -> P.Output {
        defer { Task { await cleanCompletedInFlights() } }
        
        if let existing = inFlights[key], !existing.didComplete {
            return try await existing.attach()
        } else {
            let inflight = InFlight(id: nil, publisher: createPublisher(key))
            inFlights[key] = inflight
            return try await inflight.attach()
        }
    }
    
    public func throwInFlights(where condition: (HashKey) -> Bool, error: APIError) async {
        inFlights = inFlights.filter({ inFlight in
            guard condition(inFlight.key) else { return true }
            inFlight.value.throw(error: error)
            return false
        })
    }
    
    public func throwAllInFlights(error: APIError) async {
        inFlights.forEach({ inFlight in
            inFlight.value.throw(error: error)
        })
        inFlights = [:]
    }
}

private extension PiggyBacker {
    
    func cleanCompletedInFlights() async {
        inFlights = inFlights.filter({ key, value in
            return !value.didComplete
        })
    }
}

public extension PiggyBacker {
    
    final class InFlight {
        
        let id: ID?
        var didComplete: Bool { riders <= 0 && publisherFinished }
        
        private var publisherFinished = false
        private var riders = 0
        
        private var cancellables: [AnyCancellable] = []
        private let subject: PassthroughSubject<P.Output, Error>
        private var storedValue: P.Output?
        
        fileprivate init(id: ID?, publisher: P) {
            self.id = id
            subject = PassthroughSubject()
            publisher
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }
                        guard !self.didComplete else { return }
                        Task.detached(priority: .high) { self.publisherFinished = true }
                        switch completion {
                        case .finished:
                            self.subject.send(completion: .finished)
                        case .failure(let error):
                            self.subject.send(completion: .failure(error))
                        }
                    },
                    receiveValue: { [weak self] result in
                        guard let self = self else { return }
                        self.subject.send(result)
                    }
                )
                .store(in: &cancellables)
        }
        
        func attach() async throws -> P.Output {
            return try await withUnsafeThrowingContinuation { continuation in
                riders += 1
                var didResume = false
                subject
                    .sink(
                        receiveCompletion: { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .finished:
                                if !didResume {
                                    guard let storedValue = self.storedValue else {
                                        assertionFailure("PiggyBacker finished without a value, shouldn't happen")
                                        return
                                    }
                                    continuation.resume(with: .success(storedValue))
                                    didResume = true
                                    self.riders -= 1
                                }
                            case .failure(let error):
                                continuation.resume(throwing: error)
                                didResume = true
                                self.riders -= 1
                            }
                        },
                        receiveValue: { value in
                            self.storedValue = value
                            continuation.resume(returning: value)
                            didResume = true
                            self.riders -= 1
                        }
                    )
                    .store(in: &cancellables)
            }
        }
        
        func `throw`(error: APIError) {
            subject.send(completion: .failure(error))
            publisherFinished = true
            cancellables = []
        }
    }
}
