//
//  Backend+Stubs.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
@testable import Requester

public extension Backend where Self == DefaultBackend {
    
    static func stubbed(
        baseURL: URL = URL(string: "https://www.google.com")!,
        authenticator: Authenticating? = nil,
        requestProcessors: [URLRequestProcessing] = [],
        responseProcessors: [URLResponseProcessing] = []
    ) -> Self {
        return Self(
            baseURL: baseURL,
            authenticator: authenticator,
            requestProcessors: requestProcessors,
            responseProcessors: responseProcessors
        )
    }
}
