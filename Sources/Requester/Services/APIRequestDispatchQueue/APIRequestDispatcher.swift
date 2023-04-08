//
//  APIRequestDispatcher.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
import Combine

public actor APIRequestDispatcher: APIRequestDispatching {
    
    public typealias HashKey = APIRequestDispatchHashable
    
    private let piggyBacker: PiggyBacker<HashKey, URLSession.DataTaskPublisher>
    
    private var delegates: [() -> APIRequestDispatchingDelegate?] = []
    
    public init(piggyBacker: PiggyBacker<HashKey, URLSession.DataTaskPublisher> = .init()) {
        self.piggyBacker = piggyBacker
    }
    
    @discardableResult
    public func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request, tokenID: TokenID?, urlSession: URLSession) async throws -> (Data, URLResponse) {
        return try await piggyBacker.dispatch(
            HashKey(urlRequest, apiRequest, tokenID: tokenID),
            createPublisher: { _ in
                let publisher = urlSession
                    .dataTaskPublisher(for: urlRequest)
                delegates.compactMap({ $0() }).forEach { delegate in
                    delegate?.requestDispatcher(self, didCreate: publisher, for: urlRequest)
                }
                return publisher
            }
        )
    }
    
    public func throwRequests(for tokenID: TokenID, error: APIError) async {
        await piggyBacker.throwInFlights(where: { $0.tokenID == tokenID }, error: error)
    }
    
    public func throwAllRequests(error: APIError) async {
        await piggyBacker.throwAllInFlights(error: error)
    }
    
    public func add(delegate: APIRequestDispatchingDelegate) async {
        guard self.delegates.contains(where: { $0() === delegate }) else { return }
        self.delegates.append({ [weak delegate] in delegate })
    }
    
    public func remove(delegate: APIRequestDispatchingDelegate) async {
        self.delegates.removeAll(where: { $0() === delegate })
    }
}
