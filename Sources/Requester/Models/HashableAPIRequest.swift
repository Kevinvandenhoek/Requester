//
//  HashableAPIRequest.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public struct HashableAPIRequest: Hashable {
    
    public let parameters: NSDictionary
    public let headers: [String: String]
    public let backend: APIBackend
    public let path: String
    
    public init<Request: APIRequest>(from request: Request) {
        self.parameters = request.parameters as NSDictionary
        self.headers = request.headers
        self.backend = request.backend
        self.path = request.path
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.headers == rhs.headers
            && lhs.backend.baseURL == rhs.backend.baseURL // TODO: Check if we can take all members in consideration instead of just the baseURL
            && lhs.path == rhs.path
            && lhs.parameters == rhs.parameters
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(headers)
        hasher.combine(backend.baseURL)
        hasher.combine(path)
        hasher.combine(parameters)
    }
}
