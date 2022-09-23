//
//  APIAuthenticatorMock.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
@testable import Requester

final class AuthenticatorMock: Authenticating {
    
    var shouldRefreshTokenOn401: Bool = true

    var invokedAuthenticate = false
    var invokedAuthenticateCount = 0
    var invokedAuthenticateParameters: (request: URLRequest, Void)?
    var invokedAuthenticateParametersList = [(request: URLRequest, Void)]()
    var stubbedAuthenticateResult: Result<TokenID?, AuthenticationError> = .success("TokenID")

    func authenticate(request: inout URLRequest) async -> Result<TokenID?, AuthenticationError> {
        invokedAuthenticate = true
        invokedAuthenticateCount += 1
        invokedAuthenticateParameters = (request, ())
        invokedAuthenticateParametersList.append((request, ()))
        return stubbedAuthenticateResult
    }
    
    var invokedDeleteToken = false
    var invokedDeleteTokenCount = 0
    var mockedDeleteTokenImplementation: (() async -> Void)?
    
    func deleteToken(with id: TokenID) async {
        invokedDeleteToken = true
        invokedDeleteTokenCount += 1
        await mockedDeleteTokenImplementation?()
    }
    
    var invokedFetchToken = false
    var invokedFetchTokenCount = 0
    var mockedFetchTokenImplementation: (() async throws -> Void)?

    func fetchToken() async throws {
        invokedFetchToken = true
        invokedFetchTokenCount += 1
        try await mockedFetchTokenImplementation?()
    }
}
