//
//  APIRequestDispatcher.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
import Combine

public typealias MultiCastDataTaskPublisher = Publishers.Autoconnect<Publishers.Multicast<URLSession.DataTaskPublisher, PassthroughSubject<(data: Data, response: URLResponse), URLError>>>

public actor APIRequestDispatcher: APIRequestDispatching {
    
    public typealias HashKey = APIRequestDispatchHashable
    
    private let piggyBacker: PiggyBacker<HashKey, URLSession.DataTaskFuture, APIRequestDispatchID>
    
    private var delegates: [() -> APIRequestDispatchingDelegate?] = []
    
    private var count: Int = 0
    
    public init(piggyBacker: PiggyBacker<HashKey, URLSession.DataTaskFuture, APIRequestDispatchID> = .init()) {
        self.piggyBacker = piggyBacker
    }
    
    @discardableResult
    public func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request, tokenID: TokenID?, urlSession: URLSession, dispatchId: inout APIRequestDispatchID?) async throws -> (Data, URLResponse) {
        return try await piggyBacker.dispatch(
            HashKey(urlRequest, apiRequest, tokenID: tokenID),
            id: &dispatchId,
            createPublisher: { [weak self] _ in
                // We’re currently executing on the PiggyBacker actor.
                // Hop to *our* dispatcher actor to mutate its state.
                guard let self else {
                    // If the dispatcher is gone, still create a publisher and a throwaway id.
                    return (id: -1, publisher: urlSession.future(urlRequest))
                }
                let (id, publisher, snapshot) = await self.preparePublisher(
                    urlRequest: urlRequest,
                    apiRequest: apiRequest,
                    urlSession: urlSession
                )

                // Notify delegates on the main actor (don’t capture self here).
                if !snapshot.isEmpty {
                    Task { @MainActor in
                        snapshot.forEach { delegate in
                            delegate.requestDispatcher(
                                self,
                                didCreate: publisher,
                                for: urlRequest,
                                apiRequest: apiRequest,
                                id: id
                            )
                        }
                    }
                }

                return (id: id, publisher: publisher)
            }
        )
    }
    
    @discardableResult
    public func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request, tokenID: TokenID?, urlSession: URLSession) async throws -> (Data, URLResponse) {
        var id: APIRequestDispatchID?
        return try await dispatch(urlRequest, apiRequest, tokenID: tokenID, urlSession: urlSession, dispatchId: &id)
    }
    
    public func throwRequests(for tokenID: TokenID, error: APIError) async {
        await piggyBacker.throwInFlights(where: { $0.tokenID == tokenID }, error: error)
    }
    
    public func throwAllRequests(error: APIError) async {
        await piggyBacker.throwAllInFlights(error: error)
    }
    
    public func add(delegate: APIRequestDispatchingDelegate) async {
        guard self.delegates.contains(where: { $0() === delegate }) == false else { return }
        self.delegates.append({ [weak delegate] in delegate })
    }
    
    public func remove(delegate: APIRequestDispatchingDelegate) async {
        self.delegates.removeAll(where: { $0() === delegate })
    }
    
    private func preparePublisher<Request: APIRequest>(
        urlRequest: URLRequest,
        apiRequest: Request,
        urlSession: URLSession
    ) -> (id: Int, publisher: URLSession.DataTaskFuture, snapshot: [APIRequestDispatchingDelegate]) {
        count += 1
        let id = count
        let pub = urlSession.future(urlRequest)
        // Take a snapshot so delegate callbacks aren’t racy with add/remove.
        let snapshot = delegates.compactMap { $0() }
        return (id, pub, snapshot)
    }
}
