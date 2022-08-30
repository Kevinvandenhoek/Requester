//
//  APIAuthenticator.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIAuthenticator {
    
    func authenticate(request: inout URLRequest) -> Result<Void, APIAuthenticatorError>
    func refreshToken() async throws
}

public enum APIAuthenticatorError: Error {
    case tokenMissing
    case tokenExpired
}
