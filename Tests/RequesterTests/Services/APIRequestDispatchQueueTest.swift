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
        let urlSesson = URLSession(configuration: configuration)
        sut = DefaultAPIRequestDispatchQueue(urlSession: urlSesson)
    }
    
    func test_dispatch_whenDispatchingTwoEqualRequests_shouldCombineIntoOne() async throws {
        // Given
        let apiRequest = APIRequestMock(parameters: ["name": "arie"])
        let urlRequest = try urlRequestMapper.map(apiRequest)
        
        // When
        async let requestA = sut.dispatch(urlRequest, apiRequest)
        async let requestB = sut.dispatch(urlRequest, apiRequest)
        
        // Then
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
        async let requestA = sut.dispatch(urlRequestA, apiRequestA)
        async let requestB = sut.dispatch(urlRequestB, apiRequestB)

        let requests = await self.sut.requests
        XCTAssertEqual(requests.keys.count, 2)
    }
}
