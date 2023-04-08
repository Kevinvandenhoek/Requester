//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation

public protocol APIRequestDispatchingDelegate: AnyObject {
    
    func requestDispatcher(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskPublisher, for urlRequest: URLRequest, id: APIRequestDispatchID)
}

public extension APIRequestDispatchingDelegate {
    
    func requestDispatcher(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskPublisher, for urlRequest: URLRequest, id: APIRequestDispatchID) { }
}
