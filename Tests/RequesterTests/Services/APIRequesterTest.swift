//
//  APIRequesterTest.swift
//  
//
//  Created by Kevin van den Hoek on 08/09/2022.
//

import Foundation
import XCTest

@testable import Requester

final class APIRequesterTest: XCTestCase {
    
    func test_perform_shouldRefreshTokenOn401() async throws {
        // Given
        let authenticator = AuthenticatorMock()
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
            XCTAssertEqual(APIErrorType.needsTokenRefresh("420"), (error as? APIError)?.type)
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
        XCTAssertEqual(authenticator.invokedFetchTokenCount, 1)
    }
    
    func test_perform_shouldNotThrowErrorOn500IfValidStatusCodesIsNil() async throws {
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
        try await sut.perform(APIRequestMock(backend: .stubbed(authenticator: authenticator)))
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
        XCTAssertEqual(authenticator.invokedFetchTokenCount, 0)
    }
    
    
    func test_perform_shouldThrowErrorOn500IfValidStatusCodesDoesntContain500() async throws {
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
                validStatusCodes: [200...299]
            ))
        } catch {
            XCTAssertEqual(APIErrorType.general, (error as? APIError)?.type)
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
            XCTAssertEqual((error as? APIError)?.type, .needsTokenRefresh(nil))
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
        let sut = makeSUT(mockSetup: .responseHandler({ request in
            return .success((APIRequestResponseMock(id: "69").toData, HTTPURLResponse(
                url: URL(string: "about:blank")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!))
        }), memoryCacher: memoryCacherMock)
        
        // When
        let result = try await sut.performWithMemoryCaching(APIRequestMock(backend: .stubbed(authenticator: authenticator)), mapper: { response in
            return response
        })
        
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
                    path: "secondPath",
                    validStatusCodes: [200...299]
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
                    path: "firstPath",
                    validStatusCodes: [200...299]
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
    
    func makeSUT(mockSetup: MockURLSetup, memoryCacher: MemoryCaching = MemoryCacher()) -> APIRequesting {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses?.insert(MockURLProtocol.self, at: 0)
        MockURLProtocol.setup = mockSetup
        let urlSesson = URLSession(configuration: configuration)
        let queue = APIRequestDispatcher(urlSession: urlSesson)
        let sut = APIRequester(dispatcher: queue, memoryCacher: memoryCacher)
        return sut
    }
}
