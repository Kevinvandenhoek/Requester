//
//  APIAuthenticator.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

/// An identification string of a token. It can be whatever you like, as long as it uniquely identifies a token, so that it can be used to identify which in-flight url data tasks are using the same token.
public typealias TokenID = String

/// An authenticator meant for URLRequest authentication.
public protocol Authenticating {
    
    /// Authenticate the URLRequest and return an identifier if any token is used for authentication. If a missingToken error is returned, a refreshToken call will be triggered. Simply return nil if no token is needed
    func authenticate(request: inout URLRequest) async -> Result<TokenID?, AuthenticationError>
    /// Delete the token from your storage as it has been invalidated.
    func deleteToken(with id: TokenID) async
    /// Fetch and store a new token for you to use in future 'authenticate' calls
    func fetchToken() async throws
    
    /// If the HTTPResponse contains a 401 code, returning true here will automatically trigger a token refresh and a single retry on the previously attempted APIRequest. If the APIRequest then fails again the APIRequester will throw an error, regardless of the type of error.
    var shouldRefreshTokenOn401: Bool { get }
}

public extension Authenticating {
    
    var shouldRefreshTokenOn401: Bool { true }
}

public enum AuthenticationError: Error {
    case missingToken
}
