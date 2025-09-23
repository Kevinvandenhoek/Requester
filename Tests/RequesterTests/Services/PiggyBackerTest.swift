//
//  PiggyBackerTest.swift
//  Requester
//
//  Created by Kevin van den Hoek on 23/09/2025.
//

import Foundation
import XCTest
import Requester
import Combine

final class PiggyBackerTest: XCTestCase {
    
    func test_whenDispatching_shouldReturnFutureCompletion() async throws {
        // Given
        let sut = PiggyBacker<String, Future<String, Error>, APIRequestDispatchID>()
        let resultString = "completed"
        
        // When
        let result = try await sut.dispatch("a") { id in
            return Future<String, Error>() { promise in
                promise(.success(resultString))
            }
        }
        
        // Then
        XCTAssertEqual(resultString, result)
    }
    
    func test_whenDispatchingMultipleWithDifferentId_shouldReturnMatchingResults() async throws {
        // Given
        let sut = PiggyBacker<String, Future<String, Error>, APIRequestDispatchID>()
        let resultAString = "resultAString"
        let resultBString = "resultBString"
        
        // When
        async let aTask = try await sut.dispatch("a") { id in
            return Future.delayed(1, result: .success(resultAString))
        }
        async let bTask = try await sut.dispatch("b") { id in
            return Future.delayed(1, result: .success(resultBString))
        }
        
        // Then
        let (a, b) = try await (aTask, bTask)
        XCTAssertEqual(a, resultAString)
        XCTAssertEqual(b, resultBString)
    }
    
    func test_whenDispatchingMultipleWithSameId_shouldReturnFirstMatchForId() async throws {
        // Given
        let sut = PiggyBacker<String, Future<String, Error>, APIRequestDispatchID>()
        let resultAString = "resultAString"
        let resultBString = "resultBString"
        
        // When
        async let aTask = try await sut.dispatch("same") { id in
            return Future.delayed(1, result: .success(resultAString))
        }
        async let bTask = try await sut.dispatch("same") { id in
            return Future.delayed(1, result: .success(resultBString))
        }
        
        // Then
        let (a, b) = try await (aTask, bTask)
        XCTAssertEqual(a, resultAString)
        XCTAssertEqual(b, resultAString)
    }
    
    func test_whenDispatchingManyTasksWithSameId_shouldAllReturnFirstTaskResult() async throws {
        // Given
        let sut = PiggyBacker<String, Future<String, Error>, APIRequestDispatchID>()
        let firstTaskResult = "firstTaskResult"
        let taskCount = 1_000_000
        
        // When
        let results = try await withThrowingTaskGroup(of: String.self) { group in
            for i in 0..<taskCount {
                group.addTask {
                    try await sut.dispatch("piggyback") { id in
                        if i == 0 {
                            return Future.delayed(5, result: .success("firstTaskResult"))
                        } else {
                            return Future.delayed(5, result: .success("task_\(i)_result"))
                        }
                    }
                }
            }
            var out: [String] = []
            out.reserveCapacity(taskCount)
            for try await r in group { out.append(r) }
            return out
        }
        
        // All results should be the same (from the first task that actually executed)
        XCTAssertEqual(results.count, taskCount)
        results.forEach { result in
            XCTAssertEqual(result, firstTaskResult)
        }
    }
}

private extension Future {
    
    static func delayed(_ delay: TimeInterval, result: Result<Output, Failure>) -> Future<Output, Failure> {
        return Future<Output, Failure>() { promise in
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                promise(result)
            }
        }
    }
}
