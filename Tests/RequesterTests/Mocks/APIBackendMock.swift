//
//  APIBackendMock.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
@testable import Requester

public struct APIBackendMock: APIBackend {
    
    public let baseURL: URL
    public let authenticator: APIAuthenticator?
    public let requestProcessor: URLRequestProcessor?
    public let responseProcessor: URLResponseProcessor?
    
    public init(baseURL: URL = URL(string: "about:blank")!, authenticator: APIAuthenticator? = nil, requestProcessor: URLRequestProcessor? = nil, responseProcessor: URLResponseProcessor? = nil) {
        self.baseURL = baseURL
        self.authenticator = authenticator
        self.requestProcessor = requestProcessor
        self.responseProcessor = responseProcessor
    }
}
