//
//  Backend.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol Backend {
    
    var baseURL: URL { get }
    var authenticator: Authenticating? { get }
    var requestProcessors: [URLRequestProcessing] { get }
    var responseProcessors: [URLResponseProcessing] { get }
}
