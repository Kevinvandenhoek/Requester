//
//  URLSessionManaging.swift
//  
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation

protocol URLSessionManaging {
    
    func urlSession<Request: APIRequest>(for request: Request) async -> URLSession
}

actor URLSessionManager: URLSessionManaging {
    
    private let urlSessionConfigurationProvider: URLSessionConfigurationProviding
    private var urlSessions: [URLSessionHashKey: Item] = [:]
    private weak var delegate: URLSessionDelegate?
    
    init(urlSessionConfigurationProvider: URLSessionConfigurationProviding = URLSessionConfigurationProvider(), delegate: URLSessionDelegate?) {
        self.urlSessionConfigurationProvider = urlSessionConfigurationProvider
        self.delegate = delegate
    }
    
    func urlSession<Request: APIRequest>(for request: Request) async -> URLSession {
        let (config, id) = urlSessionConfigurationProvider.make(for: request)
        let hashKey = URLSessionHashKey(config, id: id)
        if let existing = urlSessions[hashKey] {
            return existing.urlSession
        } else {
            let newItem = Item(config: config, delegate: delegate)
            urlSessions[hashKey] = newItem
            return newItem.urlSession
        }
    }
}

extension URLSessionManager {
    
    private struct Item {
        
        let urlSession: URLSession
        let config: URLSessionConfiguration
        weak var delegate: URLSessionDelegate?
        
        init(config: URLSessionConfiguration, delegate: URLSessionDelegate?) {
            self.config = config
            self.delegate = delegate
            self.urlSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        }
    }
}

private struct URLSessionHashKey: Hashable {
    
    let configuration: URLSessionConfiguration
    let id: URLSessionID?
    
    init(_ configuration: URLSessionConfiguration, id: URLSessionID? = nil) {
        self.configuration = configuration
        self.id = id
    }
}
