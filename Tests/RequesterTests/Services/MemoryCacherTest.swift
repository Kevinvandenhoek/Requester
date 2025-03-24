//
//  MemoryCacheTest.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
import XCTest

@testable import Requester

@MainActor final class MemoryCacheTest: XCTestCase {
    
    private var sut: MemoryCacher!
    
    override func setUp() {
        super.setUp()
        sut = MemoryCacher()
    }
    
    func test_get_afterStore_shouldReturnStoredValueForSameRequest() async {
        // Given
        let model = APIRequestResponseMock(id: "1")
        let request = APIRequestMock(parameters: ["name": "arie"])
        await sut.store(request: request, model: model)
        
        // When
        let result: APIRequestResponseMock? = await sut.get(request: request)
        
        // Then
        XCTAssertEqual(model, result)
    }
    
    func test_get_afterStore_shouldReturnNilAfterClearingRelevantUseCase() async {
        // Given
        let cachingGroup = CachingGroupMock(id: "1")
        let model = APIRequestResponseMock(id: "1")
        let request = APIRequestMock(parameters: ["name": "arie"], cachingGroups: [cachingGroup])
        await sut.store(request: request, model: model)
        await sut.clear([cachingGroup])
        
        // When
        let result: [APIRequestResponseMock]? = await sut.get(request: request)
        
        // Then
        XCTAssertNil(result)
    }
    
    func test_get_afterStore_shouldReturnStoredAfterClearingIrrelevantUseCase() async {
        // Given
        let model = APIRequestResponseMock(id: "1")
        let request = APIRequestMock(parameters: ["name": "arie"], cachingGroups: [CachingGroupMock(id: "1")])
        await sut.store(request: request, model: model)
        await sut.clear([CachingGroupMock(id: "2")])
        
        // When
        let result: APIRequestResponseMock? = await sut.get(request: request)
        
        // Then
        XCTAssertNotNil(result)
    }
    
    func test_get_afterStore_shouldReturnStoredValueForDifferentRequest() async {
        // Given
        let model = APIRequestResponseMock(id: "1")
        let request = APIRequestMock(parameters: ["name": "arie"])
        await sut.store(request: request, model: model)
        
        // When
        let result: APIRequestResponseMock? = await sut.get(request: APIRequestMock(parameters: ["name": "jantje"]))
        
        // Then
        XCTAssertNil(result)
    }
}
