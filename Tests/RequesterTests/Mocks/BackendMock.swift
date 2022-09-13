//
//  BackendMock.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
@testable import Requester

public struct BackendMock: Backend {
    
    public let baseURL: URL
    public let authenticator: Authenticating?
    public let requestProcessor: URLRequestProcessing?
    public let responseProcessor: URLResponseProcessing?
    
    public init(baseURL: URL = URL(string: "https://www.google.com")!, authenticator: Authenticating? = nil, requestProcessor: URLRequestProcessing? = nil, responseProcessor: URLResponseProcessing? = nil) {
        self.baseURL = baseURL
        self.authenticator = authenticator
        self.requestProcessor = requestProcessor
        self.responseProcessor = responseProcessor
    }
}
