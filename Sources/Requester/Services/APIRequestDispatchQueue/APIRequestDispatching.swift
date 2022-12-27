//
//  APIRequestDispatching.swift
//  
//
//  Created by Kevin van den Hoek on 09/09/2022.
//

import Foundation

public protocol APIRequestDispatching {
    
    @discardableResult
    func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request, tokenID: TokenID?, urlSession: URLSession) async throws -> (Data, URLResponse)
    func throwRequests(for tokenID: TokenID, error: APIError) async
    func throwAllRequests(error: APIError) async
}
