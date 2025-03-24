//
//  APIRequesterTest.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
import XCTest

@testable import Requester

@MainActor final class APIRequesterTest: XCTestCase {
    
    func test_perform_shouldRefreshTokenOn401() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.mockedShouldRefreshToken = { _, _ in true }
        let tokenID = "420"
        authenticator.stubbedAuthenticateResult = .success(tokenID)
        let sut = makeSUT(mockSetup: .responseHandler { request in
            return .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        do {
            try await sut.perform(APIRequestMock(backend: .stubbed(authenticator: authenticator)))
        } catch {
            XCTAssertEqual(APIErrorType.invalidToken("420"), (error as? APIError)?.type, "returned error had message : \(String(describing: (error as? APIError)?.message))")
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
        XCTAssertEqual(authenticator.invokedFetchTokenCount, 1)
    }
    
    func test_perform_shouldNotThrowErrorOn500IfValidStatusCodeValidationIsNone() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        let sut = makeSUT(mockSetup: .responseHandler { request in
            let data = APIRequestResponseMock(id: "69").toData
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return .success((data, response))
        })
        
        // When
        try await sut.perform(APIRequestMock(
            backend: .stubbed(authenticator: authenticator),
            statusCodeValidation: StatusCodeValidation.none
        ))
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
        XCTAssertEqual(authenticator.invokedFetchTokenCount, 0)
    }
    
    
    func test_perform_shouldThrowErrorOn500IfDefaultStatusCodeValidation() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        let sut = makeSUT(mockSetup: .responseHandler { request in
            return .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        do {
            try await sut.perform(APIRequestMock(
                backend: .stubbed(authenticator: authenticator),
                statusCodeValidation: .default
            ))
        } catch {
            XCTAssertEqual(APIErrorType.invalidStatusCode, (error as? APIError)?.type)
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
        XCTAssertEqual(authenticator.invokedFetchTokenCount, 0)
    }
    
    func test_perform_shouldFetchTokenIfMissingTokenIsReturnedAndShouldRefreshIsSetToTrue() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.stubbedAuthenticateResult = .failure(.missingToken)
        authenticator.mockedFetchTokenImplementation = {
            authenticator.stubbedAuthenticateResult = .success("420")
            MockURLProtocol.setup = .responseHandler { request in
                return .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!))
            }
        }
        let sut = makeSUT(mockSetup: .responseHandler { request in
            return .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        try await sut.perform(APIRequestMock(backend: .stubbed(authenticator: authenticator)))
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
        XCTAssertEqual(authenticator.invokedFetchTokenCount, 1)
    }
    
    func test_perform_shouldNotFetchTokenIfMissingTokenIsReturnedAndShouldRefreshIsSetToFalse() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.stubbedAuthenticateResult = .success("69")
        authenticator.mockedShouldRefreshToken = { _, _ in
            return false
        }
        let sut = makeSUT(mockSetup: .responseHandler { request in
            return .success((APIRequestResponseMock(id: "420").toData, HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        do {
            try await sut.perform(APIRequestMock(backend: .stubbed(authenticator: authenticator)))
            XCTFail("Expect unauthorized error")
        } catch {
            // Then
            XCTAssertEqual((error as? APIError)?.type, .unauthorized)
            XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
            XCTAssertEqual(authenticator.invokedFetchTokenCount, 0)
        }
    }
    
    func test_perform_ifAutenticatorReturnsSuccessWithoutTokenID_shouldFetchToken() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.stubbedAuthenticateResult = .success(nil)
        let sut = makeSUT(mockSetup: .responseHandler { request in
            return .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!))
        })
        
        // When
        do {
            try await sut.perform(APIRequestMock(backend: .stubbed(authenticator: authenticator)))
            XCTFail("Expect unauthenticated error")
        } catch {
            // Then
            XCTAssertEqual((error as? APIError)?.type, .missingToken)
            XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
            XCTAssertEqual(authenticator.invokedFetchTokenCount, 1)
        }
    }
    
    func test_performWithMemoryCaching_shouldPassTimeoutToMemoryCacher() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.stubbedAuthenticateResult = .success(nil)
        let memoryCacherMock = MemoryCacherMock()
        let memoryCachedItem = APIRequestResponseMock(id: "420")
        memoryCacherMock.stubbedGetResult = memoryCachedItem
        let sut = makeSUT(memoryCacher: memoryCacherMock, mockSetup: .responseHandler({ request in
            return .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: URL(string: "about:blank")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!))
        }))
        
        // When
        let result = try await sut.perform(
            APIRequestMock(backend: .stubbed(authenticator: authenticator)),
            cacheLifetime: .greatestFiniteMagnitude,
            mapper: { response in
                return response
            }
        )
        
        // Then
        XCTAssertEqual(memoryCachedItem, result)
    }
    
    func test_whenFiringMultipleEqualRequests_whenReceivingNoToken_shouldCancelAllRelatedRequests() {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.stubbedAuthenticateResult = .success("4")
        authenticator.mockedFetchTokenImplementation = {
            throw APIError(type: .general)
        }
        let sut = makeSUT(mockSetup: .byPath([
            "/firstPath": (duration: 0.5, result: .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: URL(string: "about:blank")!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!))),
            "/secondPath": (duration: 3, result: .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: URL(string: "about:blank")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!)))
        ]))
        let expectation = self.expectation(description: "should cancel second request")
        
        // When
        Task.detached(priority: .userInitiated) {
            do {
                try await sut.perform(APIRequestMock(
                    backend: .stubbed(authenticator: authenticator),
                    path: "secondPath"
                ))
                XCTFail("secondPath should fail")
            } catch {
                expectation.fulfill()
            }
        }
        Task.detached(priority: .userInitiated) {
            do {
                try await sut.perform(APIRequestMock(
                    backend: .stubbed(authenticator: authenticator),
                    path: "firstPath"
                ))
                XCTFail("firstPath should fail")
            } catch {
                // Nothing here
            }
        }
        
        waitForExpectations(timeout: 3, handler: { error in
            guard let error = error else { return }
            XCTFail(error.localizedDescription)
        })
    }
}

private extension APIRequesterTest {
    
    func makeSUT(memoryCacher: MemoryCaching = MemoryCacher(), mockSetup: MockURLSetup) -> APIRequesting {
        let queue = APIRequestDispatcher()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses?.insert(MockURLProtocol.self, at: 0)
        MockURLProtocol.setup = mockSetup
        let urlSessionConfigurationProvider = URLSessionConfigurationProviderMock(stubbedURLConfiguration: configuration)
        let sut = APIRequester(dispatcher: queue, memoryCacher: memoryCacher, urlSessionConfigurationProvider: urlSessionConfigurationProvider)
        return sut
    }
}
