//
//  URLSessionConfigurationProvider.swift
//  
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation

public struct URLSessionConfigurationProvider: URLSessionConfigurationProviding {
    
    public init() { }
    
    public func make<Request: APIRequest>(for request: Request) -> URLSessionConfiguration {
        return URLSession.shared.configuration
    }
}
