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
    private var urlSessions: [URLSessionConfiguration: Item] = [:]
    private weak var delegate: URLSessionDelegate?
    
    init(urlSessionConfigurationProvider: URLSessionConfigurationProviding = URLSessionConfigurationProvider(), delegate: URLSessionDelegate?) {
        self.urlSessionConfigurationProvider = urlSessionConfigurationProvider
        self.delegate = delegate
    }
    
    func urlSession<Request: APIRequest>(for request: Request) async -> URLSession {
        let config = urlSessionConfigurationProvider.make(for: request)
        if let existing = urlSessions[config] {
            return existing.urlSession
        } else {
            let newItem = Item(config: config, delegate: delegate)
            urlSessions[config] = newItem
            return newItem.urlSession
        }
    }
}

extension URLSessionManager {
    
    private class Item: NSObject, URLSessionDelegate {
        
        lazy var urlSession: URLSession = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        let config: URLSessionConfiguration
        weak var delegate: URLSessionDelegate?
        
        init(config: URLSessionConfiguration, delegate: URLSessionDelegate?) {
            self.config = config
            self.delegate = delegate
        }
    }
}
