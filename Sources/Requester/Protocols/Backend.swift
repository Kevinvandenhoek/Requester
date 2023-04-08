//
//  Backend.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol Backend {
    var baseURL: URL { get }
    var authenticator: Authenticating? { get }
    var requestProcessors: [URLRequestProcessing] { get }
    var responseProcessors: [URLResponseProcessing] { get }
    var sslCertificates: [Base64String] { get }
}

public extension Backend where Self == DefaultBackend {

    static func `default`(
        baseURL: URL,
        authenticator: Authenticating? = nil,
        requestProcessors: [URLRequestProcessing] = [],
        responseProcessors: [URLResponseProcessing] = [],
        sslCertificates: [Base64String] = []
    ) -> Self {
        return Self(
            baseURL: baseURL,
            authenticator: authenticator,
            requestProcessors: requestProcessors,
            responseProcessors: responseProcessors,
            sslCertificates: sslCertificates
        )
    }
}

public struct DefaultBackend: Backend {
    
    public let baseURL: URL
    public let authenticator: Authenticating?
    public let requestProcessors: [URLRequestProcessing]
    public let responseProcessors: [URLResponseProcessing]
    public let sslCertificates: [Base64String]
    
    public init(baseURL: URL, authenticator: Authenticating? = nil, requestProcessors: [URLRequestProcessing] = [], responseProcessors: [URLResponseProcessing] = [], sslCertificates: [Base64String] = []) {
        self.baseURL = baseURL
        self.authenticator = authenticator
        self.requestProcessors = requestProcessors
        self.responseProcessors = responseProcessors
        self.sslCertificates = sslCertificates
    }
}
