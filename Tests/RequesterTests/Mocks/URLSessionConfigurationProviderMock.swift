//
//  URLSessionConfigurationProviderMock.swift
//  
//
//  Created by Kevin van den Hoek on 23/12/2022.
//

import Foundation
import Requester

struct URLSessionConfigurationProviderMock: URLSessionConfigurationProviding {
    
    let stubbedURLConfiguration: URLSessionConfiguration
    let stubbedUrlSessionId: URLSessionID?
    
    init(stubbedURLConfiguration: URLSessionConfiguration? = nil, stubbedUrlSessionId: URLSessionID? = nil) {
        if let stubbedURLConfiguration {
            self.stubbedURLConfiguration = stubbedURLConfiguration
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses?.insert(MockURLProtocol.self, at: 0)
            self.stubbedURLConfiguration = configuration
        }
        self.stubbedUrlSessionId = stubbedUrlSessionId
    }
    
    public func make<Request: APIRequest>(for request: Request) -> (URLSessionConfiguration, URLSessionID?) {
        return (stubbedURLConfiguration, stubbedUrlSessionId)
    }
}
