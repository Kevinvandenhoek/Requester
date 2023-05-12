//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 01/09/2022.
//

import Foundation
import Combine

public extension URLSession {
    
    typealias DataTaskFuture = Future<(data: Data, response: URLResponse), Error>
    
    func future(_ request: URLRequest) -> DataTaskFuture {
        return DataTaskFuture { promise in
            Task {
                do {
                    let data = try await self.data(request)
                    promise(.success(data))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    func data(_ request: URLRequest) async throws -> (Data, URLResponse) {
        if #available(iOS 15.0, *) {
            return try await data(for: request)
        } else {
            return try await withUnsafeThrowingContinuation { continuation in
                let task = dataTask(with: request) { data, response, error in
                    if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: error ?? APIError(type: .general))
                    }
                }
                task.resume()
            }
        }
    }
}
