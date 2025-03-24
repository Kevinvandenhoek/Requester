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
public protocol Authenticating: Sendable {
    
    /// Authenticate the URLRequest and return an arbitrary identifier to identify the token used for authentication. If a missingToken error is returned, a refreshToken call will be triggered. Providing an identifier for the token will ensure all existing requests using the same token will be cancelled if any token expiration is detected. These calls will then be silently retried when the token is refreshed.
    func authenticate(request: inout URLRequest) async -> Result<TokenID?, AuthenticationError>
    /// Fetch and store a new token for you to use in future 'authenticate' calls
    func fetchToken() async throws
    
    /// The default implementation is a check if the status code is 401, in which case it will return true.
    func shouldRefreshToken<Request: APIRequest>(request: Request, response: HTTPURLResponse, data: Data) async -> Bool
}

public extension Authenticating {
    
    func shouldRefreshToken<Request: APIRequest>(request: Request, response: HTTPURLResponse, data: Data) async -> Bool {
        return response.statusCode == 401
    }
}

public enum AuthenticationError: Error {
    case missingToken
}
