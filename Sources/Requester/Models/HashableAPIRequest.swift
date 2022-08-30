//
//  HashableAPIRequest.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

struct HashableAPIRequest: Hashable {
    
    let parameters: NSDictionary
    let headers: [String: String]
    let backend: APIBackend
    let path: String
    
    init<Request: APIRequest>(from request: Request) {
        self.parameters = request.parameters as NSDictionary
        self.headers = request.headers
        self.backend = request.backend
        self.path = request.path
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.headers == rhs.headers
            && lhs.backend.baseURL == rhs.backend.baseURL // TODO: Check if we can take all members in consideration instead of just the baseURL
            && lhs.path == rhs.path
            && lhs.parameters == rhs.parameters
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(headers)
        hasher.combine(backend.baseURL)
        hasher.combine(path)
        hasher.combine(parameters)
    }
}
