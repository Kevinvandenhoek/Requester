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
    var stubbedAuthenticateResult: Result<TokenID?, AuthenticationError> = .success("TokenID")

    func authenticate(request: inout URLRequest) async -> Result<TokenID?, AuthenticationError> {
        invokedAuthenticate = true
        invokedAuthenticateCount += 1
        invokedAuthenticateParameters = (request, ())
        invokedAuthenticateParametersList.append((request, ()))
        return stubbedAuthenticateResult
    }
    
    var invokedFetchToken = false
    var invokedFetchTokenCount = 0
    var mockedFetchTokenImplementation: (() async throws -> Void)?

    func fetchToken() async throws {
        invokedFetchToken = true
        invokedFetchTokenCount += 1
        try await mockedFetchTokenImplementation?()
    }
    
    var invokedShouldRefreshToken: Bool = false
    var invokedShouldRefreshTokenCount: Int = 0
    var mockedShouldRefreshToken: ((HTTPURLResponse, Data) -> Bool)?
    
    func shouldRefreshToken(response: HTTPURLResponse, data: Data) -> Bool {
        invokedShouldRefreshToken = true
        invokedShouldRefreshTokenCount += 1
        return mockedShouldRefreshToken?(response, data) ?? (response.statusCode == 401)
    }
}
