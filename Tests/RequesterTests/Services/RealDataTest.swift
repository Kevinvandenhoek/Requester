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
        
        // When
        do {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * 0.01))
                await dispatcher.throwAllRequests(error: APIError(type: .general))
            }
            try await sut.perform(request)
            XCTFail("Expected APIError")
        } catch {
            print("got error: \(error)")
            XCTAssertEqual((error as? APIError)?.type, .general, "\(error) was not of type .general")
        }
    }
}
