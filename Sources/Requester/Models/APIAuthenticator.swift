//
//  APIAuthenticator.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIAuthenticator {
    
    /// If for any reason authentication fails, return false
    func authenticate(request: inout URLRequest) async throws
    func refreshToken() async throws
}
