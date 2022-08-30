//
//  APIBackend.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIBackend {
    
    var baseURL: URL { get }
    var authenticator: APIAuthenticator? { get }
    var requestProcessor: URLRequestProcessor? { get }
    var responseProcessor: URLResponseProcessor? { get }
}
