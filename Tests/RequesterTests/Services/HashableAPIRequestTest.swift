//
//  HashableAPIRequestTest.swift
//  Requester
//
//  Created by Kevin van den Hoek on 23/09/2025.
//

import Foundation
import XCTest
import Requester

@MainActor final class HashableAPIRequestTest: XCTestCase {
    
    func test_isEqual_whenParameterValuesDiffer_shouldReturnFalse() async {
        // Given
        let requestA = APIRequestMock(parameters: ["name": "a"])
        let requestB = APIRequestMock(parameters: ["name": "b"])
        
        // When
        let isEqual = requestA == requestB
        
        // Then
        XCTAssertFalse(isEqual)
    }
    
    func test_isEqual_whenParameterValuesAreTheSame_shouldReturnTrue() async {
        // Given
        let requestA = APIRequestMock(parameters: ["name": "a"])
        let requestB = APIRequestMock(parameters: ["name": "a"])
        
        // When
        let isEqual = requestA == requestB
        
        // Then
        XCTAssertTrue(isEqual)
    }
}
