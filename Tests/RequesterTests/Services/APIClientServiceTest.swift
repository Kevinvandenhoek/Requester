//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
import XCTest

@testable import Requester

final class APIClientServiceTest: XCTestCase {
    
    func test_perform_shouldRefreshTokenOn401() async throws {
        // Given
        let authenticator = APIAuthenticatorMock()
        let sut = makeSUT(mockResponse: { request in
            return .success((Data(), HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        do {
            try await sut.perform(APIRequestMock(backend: APIBackendMock(authenticator: authenticator)))
        } catch {
            XCTAssertEqual(APIErrorType.unauthorized, (error as? APIError)?.type)
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 1)
    }
    
    func test_perform_shouldNotThrowErrorOn500IfValidStatusCodesIsNil() async throws {
        // Given
        let authenticator = APIAuthenticatorMock()
        let sut = makeSUT(mockResponse: { request in
            let data = try! JSONEncoder().encode(APIRequestResponseMock(id: "69"))
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return .success((data, response))
        })
        
        // When
        try await sut.perform(APIRequestMock(backend: APIBackendMock(authenticator: authenticator)))
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 0)
    }
    
    
    func test_perform_shouldThrowErrorOn500IfValidStatusCodesDoesntContain500() async throws {
        // Given
        let authenticator = APIAuthenticatorMock()
        let sut = makeSUT(mockResponse: { request in
            return .success((Data(), HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        do {
            try await sut.perform(APIRequestMock(
                backend: APIBackendMock(authenticator: authenticator),
                validStatusCodes: [200...299]
            ))
        } catch {
            XCTAssertEqual(APIErrorType.general, (error as? APIError)?.type)
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 0)
    }
    
    func test_perform_shouldThrowMissingTokenIfAuthenticationFails() async throws {
        // Given
        let authenticator = APIAuthenticatorMock()
        authenticator.stubbedAuthenticateResult = .failure(APIError(type: .general))
        let sut = makeSUT(mockResponse: { request in
            return .success((Data(), HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        do {
            try await sut.perform(APIRequestMock(backend: APIBackendMock(authenticator: authenticator)))
        } catch {
            XCTAssertEqual(APIErrorType.missingToken, (error as? APIError)?.type)
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 1)
    }
}

private extension APIClientServiceTest {
    
    func makeSUT(mockResponse responseHandler: @escaping (URLRequest) -> Result<(Data, HTTPURLResponse), Error>) -> APIClient {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses?.insert(MockURLProtocol.self, at: 0)
        MockURLProtocol.responseHandler = responseHandler
        let urlSesson = URLSession(configuration: configuration)
        let queue = DefaultAPIRequestDispatchQueue(urlSession: urlSesson)
        let sut = APIClientService(dispatchQueue: queue)
        return sut
    }
}
