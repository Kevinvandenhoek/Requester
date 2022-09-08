//
//  APIAuthenticatorMock.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
@testable import Requester

final class APIAuthenticatorMock: APIAuthenticator {

    var invokedAuthenticate = false
    var invokedAuthenticateCount = 0
    var invokedAuthenticateParameters: (request: URLRequest, Void)?
    var invokedAuthenticateParametersList = [(request: URLRequest, Void)]()
    var stubbedAuthenticateResult: Bool! = false

    func authenticate(request: inout URLRequest) -> Bool {
        invokedAuthenticate = true
        invokedAuthenticateCount += 1
        invokedAuthenticateParameters = (request, ())
        invokedAuthenticateParametersList.append((request, ()))
        return stubbedAuthenticateResult
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
