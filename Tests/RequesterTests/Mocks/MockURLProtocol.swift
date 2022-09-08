//
//  MockURLProtocol.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
import Requester

// Can be used to return mocked url responses
final class MockURLProtocol: URLProtocol {
    
    static var responseHandler: ((URLRequest) -> Result<(Data, HTTPURLResponse), Error>)?
    
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
        switch Self.responseHandler?(request) {
        case .success((let data, let response)):
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        default:
            client?.urlProtocol(self, didFailWithError: APIError(type: .general))
        }
    }
    
    override func stopLoading() {
        
    }
}
