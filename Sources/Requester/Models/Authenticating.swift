//
//  APIAuthenticator.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol Authenticating {
    
    /// Authenticate the URLRequest and return the token id used for authentication
    func authenticate(request: inout URLRequest) async -> TokenID?
    func deleteToken() async
    func refreshToken() async throws
}
