//
//  MockURLProtocol.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
import Requester

enum MockURLSetup {
    case responseHandler((URLRequest) -> Result<(Data, HTTPURLResponse), Error>)
    case byPath([String: (duration: TimeInterval, result: Result<(Data, HTTPURLResponse), Error>)])
}

// Can be used to return mocked url responses
final class MockURLProtocol: URLProtocol {
    
    static var setup: MockURLSetup = .byPath([:])
    
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
        Task {
            print("loading for path: \(request.url!.path)")
            switch Self.setup {
            case .byPath(let mocks):
                let delay = mocks[request.url!.path]?.duration ?? .zero
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * delay))
                print("\(request.url!.path) delay was awaited")
                switch mocks[request.url!.path]?.result {
                case .success((let data, let response)):
                    print("\(request.url!.path) success")
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case .failure(let error):
                    print("\(request.url!.path) failure \(error)")
                    client?.urlProtocol(self, didFailWithError: error)
                default:
                    print("\(request.url!.path) failure")
                    client?.urlProtocol(self, didFailWithError: APIError(type: .general))
                }
            case .responseHandler(let handler):
                switch handler(request) {
                case .success((let data, let response)):
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    client?.urlProtocol(self, didLoad: data)
                    client?.urlProtocolDidFinishLoading(self)
                case .failure(let error):
                    client?.urlProtocol(self, didFailWithError: error)
                }
            }
        }
    }
    
    override func stopLoading() {
        
    }
}
