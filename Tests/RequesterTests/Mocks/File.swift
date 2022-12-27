//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 23/12/2022.
//

import Foundation
import Requester

struct URLSessionProviderMock: URLSessionProviding {
    
    let stubbedURLSession: URLSession
    
    init(stubbedURLSession: URLSession? = nil) {
        if let stubbedURLSession {
            self.stubbedURLSession = stubbedURLSession
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses?.insert(MockURLProtocol.self, at: 0)
            self.stubbedURLSession = URLSession(configuration: configuration)
        }
    }
    
    func urlSession<Request: APIRequest>(for request: Request) -> URLSession {
        return stubbedURLSession
    }
}
