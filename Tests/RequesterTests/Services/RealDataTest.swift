//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 13/09/2022.
//

import Foundation
import XCTest
import Requester

final class RealDataTest: XCTestCase {
    
    lazy var dispatcher = APIRequestDispatcher()
    lazy var sut = APIRequester(dispatcher: dispatcher)
    
    func test_throwAllRequests_shouldThrowAllRequests() async {
        // Given
        let request = TestAPIRequest()
        let expectation = self.expectation(description: "expected failure result")
        
        // When
        perform(request, completion: { result in
            // Then
            switch result {
            case .success:
                XCTFail("Expected APIError")
            case .failure(let error):
                print("got error: \(error)")
                XCTAssertEqual((error as? APIError)?.type, .general, "\(error) was not of type .general")
                expectation.fulfill()
            }
        })
        try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * 0.5))
        await dispatcher.throwAllRequests(error: APIError(type: .general))
        
        await waitForExpectations(timeout: 3)
    }
}

extension RealDataTest {
    func perform<Request: APIRequest>(_ apiRequest: Request, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await sut.perform(apiRequest)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
