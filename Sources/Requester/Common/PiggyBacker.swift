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
        
        if let existing = inFlights[key], await !existing.didComplete {
            id = existing.id
            return try await existing.attach()
        } else {
            let (newID, publisher) = createPublisher(key)
            id = newID
            let inflight = await InFlight(id: newID, publisher: publisher)
            inFlights[key] = inflight
            return try await inflight.attach()
        }
    }
    
    @discardableResult
    public func dispatch(_ key: HashKey, createPublisher: (HashKey) -> P) async throws -> P.Output {
        defer { Task { await cleanCompletedInFlights() } }
        
        if let existing = inFlights[key], await !existing.didComplete {
            return try await existing.attach()
        } else {
            let inflight = await InFlight(id: nil, publisher: createPublisher(key))
            inFlights[key] = inflight
            return try await inflight.attach()
        }
    }
    
    public func throwInFlights(where condition: @escaping (HashKey) -> Bool, error: APIError) async {
        inFlights = await inFlights.asyncFilter({ key, value in
            guard condition(key) else { return true }
            await value.throw(error: error)
            return false
        })
    }
    
    public func throwAllInFlights(error: APIError) async {
        for inFlight in inFlights {
            await inFlight.value.throw(error: error)
        }
        inFlights = [:]
    }
}

private extension PiggyBacker {
    
    func cleanCompletedInFlights() async {
        inFlights = await inFlights.asyncFilter({ _, value in
            return await !value.didComplete
        })
    }
}

public extension PiggyBacker {
    
    actor InFlight {
        
        let id: ID?
        var didComplete: Bool { riders <= 0 && publisherFinished }
        
        private var publisherFinished = false
        private var riders = 0
        
        private var cancellables: [AnyCancellable] = []
        private let subject: PassthroughSubject<P.Output, Error>
        private var storedValue: P.Output?
        
        fileprivate init(id: ID?, publisher: P) async {
            self.id = id
            subject = PassthroughSubject()
            publisher
                .share()
                .sink(
                    receiveCompletion: {completion in
                        Task { await self.handleCompletion(completion) }
                    },
                    receiveValue: { result in
                        Task { await self.handleReceiveValue(result) }
                    }
                )
                .store(in: &cancellables)
        }
        
        func attach() async throws -> P.Output {
            return try await self.subscribeToSubject()
        }
        
        func `throw`(error: APIError) {
            subject.send(completion: .failure(error))
            publisherFinished = true
            cancellables = []
        }
    }
}

private extension PiggyBacker.InFlight {
    
    func subscribeToSubject() async throws -> P.Output {
        typealias ResultType = Result<P.Output, Error>
        
        let stream = AsyncStream<ResultType>(ResultType.self) { continuation in
            let cancellable = self.subject.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.yield(.failure(error))
                        continuation.finish()
                    }
                },
                receiveValue: { value in
                    continuation.yield(.success(value))
                }
            )
            continuation.onTermination = { termination in
                if termination == .cancelled {
                    continuation.yield(.failure(APIError(type: .general, message: "request was cancelled")))
                }
                cancellable.cancel()
            }
        }
        
        for await result in stream {
            switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
            }
        }
        
        if let storedValue { return storedValue }
        throw APIError(type: .general, message: "Stream finished without value")
    }
    
    func handleCompletion(_ completion: Subscribers.Completion<P.Failure>) async {
        guard !didComplete else { return }
        switch completion {
        case .finished:
            subject.send(completion: .finished)
        case .failure(let error):
            subject.send(completion: .failure(error))
        }
        publisherFinished = true
    }
    
    func handleReceiveValue(_ value: P.Output) async {
        storedValue = value
        subject.send(value)
    }
}
