//
//  Backend.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public struct Backend {
    
    public let baseURL: URL
    public let authenticator: Authenticating?
    public let requestProcessors: [URLRequestProcessing]
    public let responseProcessors: [URLResponseProcessing]
    
    public init(baseURL: URL, authenticator: Authenticating? = nil, requestProcessors: [URLRequestProcessing] = [], responseProcessors: [URLResponseProcessing] = []) {
        self.baseURL = baseURL
        self.authenticator = authenticator
        self.requestProcessors = requestProcessors
        self.responseProcessors = responseProcessors
    }
}
