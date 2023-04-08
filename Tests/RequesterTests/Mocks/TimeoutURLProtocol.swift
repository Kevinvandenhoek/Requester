//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
import Requester

// Can be used to make every request basically do nothing
final class TimeoutURLProtocol: URLProtocol {
    
    static var timeout: TimeInterval = 10
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.timeout, execute: {
            self.client?.urlProtocol(self, didFailWithError: APIError(type: .general))
        })
    }
    
    override func stopLoading() {
        
    }
}
