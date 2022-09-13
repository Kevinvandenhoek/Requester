//
//  APIAuthenticatorMock.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
@testable import Requester

final class AuthenticatorMock: Authenticating {

    var invokedAuthenticate = false
    var invokedAuthenticateCount = 0
    var invokedAuthenticateParameters: (request: URLRequest, Void)?
    var invokedAuthenticateParametersList = [(request: URLRequest, Void)]()
    var stubbedAuthenticateResult: TokenID? = "TokenID"

    func authenticate(request: inout URLRequest) async -> TokenID? {
        invokedAuthenticate = true
        invokedAuthenticateCount += 1
        invokedAuthenticateParameters = (request, ())
        invokedAuthenticateParametersList.append((request, ()))
        return stubbedAuthenticateResult
    }
    
    var invokedDeleteToken = false
    var invokedDeleteTokenCount = 0
    var mockedDeleteTokenImplementation: (() async -> Void)?
    
    func deleteToken() async {
        invokedDeleteToken = true
        invokedDeleteTokenCount += 1
        await mockedDeleteTokenImplementation?()
    }
    
    var invokedRefreshToken = false
    var invokedRefreshTokenCount = 0
    var mockedRefreshTokenImplementation: (() async throws -> Void)?

    func refreshToken() async throws {
        invokedRefreshToken = true
        invokedRefreshTokenCount += 1
        try await mockedRefreshTokenImplementation?()
    }
}
