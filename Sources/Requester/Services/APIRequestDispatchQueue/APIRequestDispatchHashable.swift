//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public struct APIRequestDispatchHashable: Hashable {
    
    public let urlRequest: URLRequest
    public let apiRequest: HashableAPIRequest
    
    public init<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request) {
        self.urlRequest = urlRequest
        self.apiRequest = HashableAPIRequest(from: apiRequest)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.urlRequest == rhs.urlRequest
            && lhs.apiRequest == rhs.apiRequest
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(urlRequest)
        hasher.combine(apiRequest.headers)
        hasher.combine(apiRequest.backend.baseURL) // TODO: Check if we can take all members in consideration instead of just the baseURL
        hasher.combine(apiRequest.path)
        hasher.combine(apiRequest.parameters as NSDictionary)
    }
}
