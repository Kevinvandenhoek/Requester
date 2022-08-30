//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol URLRequestProcessor {
    
    func process(_ urlRequest: inout URLRequest) throws
}
