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
        let inFlight = inFlight(for: key, id: &id, createPublisher: createPublisher)
        return try await inFlight.attach()
    }
    
    @discardableResult
    public func dispatch(_ key: HashKey, createPublisher: (HashKey) -> P) async throws -> P.Output {
        let inFlight = inFlight(for: key, createPublisher: createPublisher)
        return try await inFlight.attach()
    }
    
    public func throwInFlights(where condition: @escaping (HashKey) -> Bool, error: APIError) async {
        inFlights = inFlights.filter({ key, value in
            guard condition(key) else { return true }
            value.throw(error: error)
            return false
        })
    }
    
    public func throwAllInFlights(error: APIError) async {
        for inFlight in inFlights {
            inFlight.value.throw(error: error)
        }
        inFlights = [:]
    }
    
    public func inFlight(for key: HashKey, id: inout ID?, createPublisher: (HashKey) -> (id: ID, publisher: P)) -> InFlight {
        if let existing = inFlights[key], !existing.didComplete {
            id = existing.id
            return existing
        } else {
            let (newID, publisher) = createPublisher(key)
            id = newID
            let inflight = InFlight(id: newID, publisher: publisher)
            inFlights[key] = inflight
            return inflight
        }
    }
    
    public func inFlight(for key: HashKey, createPublisher: (HashKey) -> P) -> InFlight {
        if let existing = inFlights[key], !existing.didComplete {
            return existing
        } else {
            let publisher = createPublisher(key)
            let inflight = InFlight(id: nil, publisher: publisher)
            inFlights[key] = inflight
            return inflight
        }
    }
}

public extension PiggyBacker {
    
    class InFlight {
        
        let id: ID?
        var didComplete: Bool { subject.value != nil }
        
        private var publisherFinished = false
        private let subject: CurrentValueSubject<Result<P.Output, Error>?, Never>
        private var cancellables: [AnyCancellable] = []
        
        fileprivate init(id: ID?, publisher: P) {
            self.id = id
            let subject: CurrentValueSubject<Result<P.Output, Error>?, Never> = CurrentValueSubject(nil)
            self.subject = subject
            publisher
                .share()
                .sink(
                    receiveCompletion: { completion in
                        guard subject.value == nil else { return }
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            subject.send(.failure(error))
                        }
                    },
                    receiveValue: { result in
                        guard subject.value == nil else { return }
                        subject.send(.success(result))
                    }
                )
                .store(in: &cancellables)
        }
        
        func attach() async throws -> P.Output {
            if let result = subject.value {
                switch result {
                case .success(let value):
                    return value
                case .failure(let error):
                    throw error
                }
            } else {
                return try await withCheckedThrowingContinuation { continuation in
                    return subject
                        .sink { value in
                            guard let value else { return }
                            continuation.resume(with: value)
                        }
                        .store(in: &cancellables)
                }
            }
        }
        
        func `throw`(error: APIError) {
            guard subject.value == nil else { return }
            subject.send(.failure(error))
        }
    }
}
