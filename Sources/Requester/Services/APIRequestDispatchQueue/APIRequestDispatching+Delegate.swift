//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation

@MainActor public protocol APIRequestDispatchingDelegate: AnyObject {
    
    func requestDispatcher<Request: APIRequest>(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskFuture, for urlRequest: URLRequest, apiRequest: Request, id: APIRequestDispatchID)
}

public extension APIRequestDispatchingDelegate {
    
    func requestDispatcher<Request: APIRequest>(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskFuture, for urlRequest: URLRequest, apiRequest: Request, id: APIRequestDispatchID) { }
}
