//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
import XCTest
@testable import Requester

final class APIRequestDispatchQueueTest: XCTestCase {
    
    var sut: DefaultAPIRequestDispatchQueue!
    let urlRequestMapper = URLRequestMapper()
    
    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses?.insert(TimeoutURLProtocol.self, at: 0)
        TimeoutURLProtocol.timeout = 1
        let urlSesson = URLSession(configuration: configuration)
        sut = DefaultAPIRequestDispatchQueue(urlSession: urlSesson)
    }
    
    func test_dispatch_whenDispatchingTwoEqualRequests_shouldCombineIntoOne() async throws {
        // Given
        let apiRequest = APIRequestMock(parameters: ["name": "arie"])
        let urlRequest = try urlRequestMapper.map(apiRequest)
        
        // When
        perform(urlRequest, apiRequest, completion: { })
        perform(urlRequest, apiRequest, completion: { })
        
        // Then
        await delay()
        let requests = await sut.requests
        XCTAssertEqual(requests.keys.count, 1)
    }
    
    func test_dispatch_whenDispatchingTwoDifferentRequests_shouldCombineIntoOne() async throws {
        // Given
        let apiRequestA = APIRequestMock(parameters: ["name": "arie"])
        let urlRequestA = try urlRequestMapper.map(apiRequestA)
        let apiRequestB = APIRequestMock(parameters: ["name": "jantje"])
        let urlRequestB = try urlRequestMapper.map(apiRequestB)
        
        // When
        perform(urlRequestA, apiRequestA, completion: { })
        perform(urlRequestB, apiRequestB, completion: { })
        
        // Then
        await delay()
        let requests = await self.sut.requests
        XCTAssertEqual(requests.keys.count, 2)
    }
    
    func test_dispatch_whenDispatchingAndCompletingTwoDifferentRequests_shouldCleanUpRequestsFromQueue() async throws {
        // Given
        let apiRequestA = APIRequestMock(parameters: ["name": "arie"])
        let urlRequestA = try urlRequestMapper.map(apiRequestA)
        let apiRequestB = APIRequestMock(parameters: ["name": "jantje"])
        let urlRequestB = try urlRequestMapper.map(apiRequestB)
        
        // When
        let _ = try? await sut.dispatch(urlRequestA, apiRequestA)
        let _ = try? await sut.dispatch(urlRequestB, apiRequestB)
        
        // Then
        let requests = await self.sut.requests
        XCTAssertEqual(requests.keys.count, 0)
    }
}

private extension APIRequestDispatchQueueTest {
    
    func delay(seconds: TimeInterval = 0.1) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
    
    func perform<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request, completion: @escaping () -> Void) {
        Task {
            let _ = try? await sut.dispatch(urlRequest, apiRequest)
            completion()
        }
    }
}
