//
//  File.swift
//
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation
import Combine

public actor PiggyBacker<HashKey: Hashable, P: Publisher> {
    
    private(set) var inFlights: [HashKey: InFlight] = [:]
    
    public init() { }
    
    @discardableResult
    public func dispatch(_ key: HashKey, createPublisher: (HashKey) -> P) async throws -> P.Output {
        defer { Task { await cleanCompletedInFlights() } }
        
        if let existing = inFlights[key], !existing.didComplete {
            return try await existing.attach()
        } else {
            let inflight = InFlight(for: createPublisher(key))
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
        
        var didComplete: Bool { riders <= 0 && publisherFinished }
        
        private var publisherFinished = false
        private var riders = 0
        
        private var cancellables: [AnyCancellable] = []
        private let subject: PassthroughSubject<P.Output, Error>
        private var storedValue: P.Output?
        
        fileprivate init(for publisher: P) {
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
                var didComplete = false
                subject
                    .sink(
                        receiveCompletion: { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .finished:
                                if !didComplete {
                                    guard let storedValue = self.storedValue else {
                                        assertionFailure("PiggyBacker finished without a value, shouldn't happen")
                                        return
                                    }
                                    continuation.resume(with: .success(storedValue))
                                    didComplete = true
                                    self.riders -= 1
                                }
                            case .failure(let error):
                                continuation.resume(throwing: error)
                                didComplete = true
                                self.riders -= 1
                            }
                        },
                        receiveValue: { value in
                            self.storedValue = value
                            continuation.resume(returning: value)
                            didComplete = true
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
