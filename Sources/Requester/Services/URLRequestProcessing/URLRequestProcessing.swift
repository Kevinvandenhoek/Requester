//
//  URLRequestProcessing.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol URLRequestProcessing: Sendable {
    
    func process(_ urlRequest: inout URLRequest) async throws
}
