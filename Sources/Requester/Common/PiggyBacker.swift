//
//  File.swift
//
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation
import Combine

public actor PiggyBacker<HashKey: Hashable, P: Publisher, ID> where P.Output: Sendable, P.Failure: Error {
    
    private(set) var inFlights: [HashKey: InFlight] = [:]
    public init() {}

    @discardableResult
    public func dispatch(
        _ key: HashKey,
        id: inout ID?,
        createPublisher: @Sendable (HashKey) async -> (id: ID, publisher: P)
    ) async throws -> P.Output {
        let inflight = try await ensureInFlight(for: key, id: &id, createPublisher: createPublisher)
        return try await inflight.attach()
    }

    @discardableResult
    public func dispatch(
        _ key: HashKey,
        createPublisher: @Sendable (HashKey) async -> P
    ) async throws -> P.Output {
        let inflight = try await ensureInFlight(for: key, createPublisher: createPublisher)
        return try await inflight.attach()
    }

    public func throwInFlights(where condition: @Sendable (HashKey) -> Bool, error: APIError) async {
        let doomed = inFlights.keys.filter(condition)
        for k in doomed {
            if let f = inFlights[k] { await f.finish(throwing: error) }
            inFlights[k] = nil
        }
    }

    public func throwAllInFlights(error: APIError) async {
        for (_, f) in inFlights { await f.finish(throwing: error) }
        inFlights.removeAll()
    }

    // MARK: helpers

    private func ensureInFlight(
        for key: HashKey,
        id: inout ID?,
        createPublisher: @Sendable (HashKey) async -> (id: ID, publisher: P)
    ) async throws -> InFlight {
        if let existing = inFlights[key], await !existing.didComplete {
            id = await existing.id as? ID
            return existing
        }
        let (newID, publisher) = await createPublisher(key)
        let inflight = InFlight(id: newID)
        inFlights[key] = inflight
        id = newID
        await inflight.start(with: publisher)   // <-- do subscription AFTER init
        return inflight
    }

    private func ensureInFlight(
        for key: HashKey,
        createPublisher: @Sendable (HashKey) async -> P
    ) async throws -> InFlight {
        if let existing = inFlights[key], await !existing.didComplete { return existing }
        let publisher = await createPublisher(key)
        let inflight = InFlight(id: nil)
        inFlights[key] = inflight
        await inflight.start(with: publisher)   // <-- do subscription AFTER init
        return inflight
    }
}

public extension PiggyBacker {
    
    actor InFlight {
        private(set) var id: Any?
        private(set) var didComplete = false

        // Replace AnyCancellable with a Task that drives the subscription.
        private var runner: Task<Void, Never>?
        private var result: Result<P.Output, Error>? = nil
        private var waiters: [CheckedContinuation<P.Output, Error>] = []

        fileprivate init(id: Any?) { self.id = id }

        func start(with publisher: P) {
            guard runner == nil, !didComplete else { return }
            runner = Task { [weak self] in
                guard let self else { return }
                do {
                    var it = publisher.values.makeAsyncIterator()
                    if let value = try await it.next() {
                        await self.handleValue(value)
                    } else {
                        // Completed without any value
                        await self.handleFinishedWithoutValue()
                    }
                } catch {
                    await self.handleError(error)
                }
            }
        }

        func attach() async throws -> P.Output {
            if let r = result {
                switch r { case .success(let v): return v; case .failure(let e): throw e }
            }
            return try await withCheckedThrowingContinuation { (c: CheckedContinuation<P.Output, Error>) in
                waiters.append(c)
            }
        }

        func finish(throwing error: Error) {
            guard !didComplete else { return }
            didComplete = true
            result = .failure(error)
            resumeAll(with: .failure(error))
            runner?.cancel(); runner = nil
        }

        // MARK: - private

        private func handleValue(_ value: P.Output) {
            guard !didComplete else { return }
            didComplete = true
            result = .success(value)
            resumeAll(with: .success(value))
            runner?.cancel(); runner = nil
        }

        private func handleError(_ error: Error) {
            guard !didComplete else { return }
            didComplete = true
            result = .failure(error)
            resumeAll(with: .failure(error))
            runner?.cancel(); runner = nil
        }

        private func handleFinishedWithoutValue() {
            guard !didComplete else { return }
            didComplete = true
            let err = CancellationError()
            result = .failure(err)
            resumeAll(with: .failure(err))
            runner?.cancel(); runner = nil
        }

        private func resumeAll(with result: Result<P.Output, Error>) {
            let cs = waiters
            waiters.removeAll(keepingCapacity: false)
            for c in cs { c.resume(with: result) }
        }
    }
}
