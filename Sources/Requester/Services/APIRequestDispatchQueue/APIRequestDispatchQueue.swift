//
//  APIRequestDispatchQueue.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
import Combine

public protocol APIRequestDispatchQueue {
    
    func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request) async throws -> (Data, URLResponse)
}

public actor DefaultAPIRequestDispatchQueue: APIRequestDispatchQueue {
    
    public let urlSession: URLSession
    
    private var requests: [HashKey: PassthroughSubject<(Data, URLResponse), Error>] = [:]
    private var cancellables: [AnyCancellable] = []
    
    public init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    public func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request) async throws -> (Data, URLResponse) {
        let key = HashKey(urlRequest, apiRequest)
        if let existing = requests[key] {
            return try await withUnsafeThrowingContinuation { continuation in
                existing.sink(
                    receiveCompletion: { result in
                        switch result {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                    }
                ).store(in: &cancellables)
            }
        } else {
            let subject = PassthroughSubject<(Data, URLResponse), Error>()
            requests[key] = subject
            do {
                let result = try await urlSession.data(for: urlRequest)
                subject.send(result)
                subject.send(completion: .finished)
                requests[key] = nil
                return result
            } catch {
                subject.send(completion: .failure(error))
                requests[key] = nil
                throw error
            }
        }
    }
}

private struct HashKey: Hashable {
    
    let urlRequest: URLRequest
    let apiRequest: HashableAPIRequest
    
    init<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request) {
        self.urlRequest = urlRequest
        self.apiRequest = HashableAPIRequest(from: apiRequest)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.urlRequest == rhs.urlRequest
            && lhs.apiRequest == rhs.apiRequest
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(urlRequest)
        hasher.combine(apiRequest.headers)
        hasher.combine(apiRequest.backend.baseURL) // TODO: Check if we can take all members in consideration instead of just the baseURL
        hasher.combine(apiRequest.path)
        hasher.combine(apiRequest.parameters as NSDictionary)
    }
}
