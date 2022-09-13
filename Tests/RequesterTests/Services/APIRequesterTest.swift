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
        authenticator.stubbedAuthenticateResult = tokenID
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
            try await sut.perform(APIRequestMock(backend: BackendMock(authenticator: authenticator)))
        } catch {
            XCTAssertEqual(APIErrorType.unauthorized(tokenID), (error as? APIError)?.type)
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 1)
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
        try await sut.perform(APIRequestMock(backend: BackendMock(authenticator: authenticator)))
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 0)
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
                backend: BackendMock(authenticator: authenticator),
                validStatusCodes: [200...299]
            ))
        } catch {
            XCTAssertEqual(APIErrorType.general, (error as? APIError)?.type)
        }
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 1)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 0)
    }
    
    func test_perform_shouldFetchTokenIfAuthenticatorHasNoToken() async throws {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.stubbedAuthenticateResult = nil
        authenticator.mockedRefreshTokenImplementation = {
            print("running mockedRefreshTokenImplementation")
            authenticator.stubbedAuthenticateResult = "420"
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
        try await sut.perform(APIRequestMock(backend: BackendMock(authenticator: authenticator)))
        
        // Then
        XCTAssertEqual(authenticator.invokedAuthenticateCount, 2)
        XCTAssertEqual(authenticator.invokedRefreshTokenCount, 1)
    }
    
    func test_whenFiringMultipleEqualRequests_whenReceivingNoToken_shouldCancelAllRelatedRequests() {
        // Given
        let authenticator = AuthenticatorMock()
        authenticator.stubbedAuthenticateResult = "4"
        authenticator.mockedRefreshTokenImplementation = {
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
                    backend: BackendMock(authenticator: authenticator),
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
                    backend: BackendMock(authenticator: authenticator),
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
    
    func makeSUT(mockSetup: MockURLSetup) -> APIRequesting {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses?.insert(MockURLProtocol.self, at: 0)
        MockURLProtocol.setup = mockSetup
        let urlSesson = URLSession(configuration: configuration)
        let queue = APIRequestDispatcher(urlSession: urlSesson)
        let sut = APIRequester(dispatcher: queue)
        return sut
    }
}
