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
    
    public init(piggyBacker: PiggyBacker<HashKey, URLSession.DataTaskPublisher> = .init()) {
        self.piggyBacker = piggyBacker
    }
    
    @discardableResult
    public func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request, tokenID: TokenID?, urlSession: URLSession) async throws -> (Data, URLResponse) {
        return try await piggyBacker.dispatch(
            HashKey(urlRequest, apiRequest, tokenID: tokenID),
            createPublisher: { _ in urlSession.dataTaskPublisher(for: urlRequest) }
        )
    }
    
    public func throwRequests(for tokenID: TokenID, error: APIError) async {
        await piggyBacker.throwInFlights(where: { $0.tokenID == tokenID }, error: error)
    }
    
    public func throwAllRequests(error: APIError) async {
        await piggyBacker.throwAllInFlights(error: error)
    }
}
