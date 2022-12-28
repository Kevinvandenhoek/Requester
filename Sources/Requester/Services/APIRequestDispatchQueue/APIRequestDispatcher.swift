//
//  APIRequestDispatcher.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
import Combine

public actor APIRequestDispatcher: APIRequestDispatching {
    
    public typealias HashKey = APIRequestDispatchHashable
    
    private(set) var inFlights: [HashKey: InFlight] = [:]
    
    public init() { }
    
    @discardableResult
    public func dispatch<Request: APIRequest>(_ urlRequest: URLRequest, _ apiRequest: Request, tokenID: TokenID?, urlSession: URLSession) async throws -> (Data, URLResponse) {
        defer { Task { await cleanCompletedInFlights() } }
        
        let key = HashKey(urlRequest, apiRequest, tokenID: tokenID)
        if let existing = inFlights[key], !existing.didComplete {
            return try await existing.attach()
        } else {
            let inflight = InFlight(for: urlSession.dataTaskPublisher(for: urlRequest))
            inFlights[key] = inflight
            print("🐛 updated to \(inFlights.count) inFlights")
            return try await inflight.attach()
        }
    }
    
    public func throwRequests(for tokenID: TokenID, error: APIError) async {
        inFlights.forEach({ inFlight in
            guard inFlight.key.tokenID == tokenID else { return }
            inFlight.value.throw(error: error)
        })
        inFlights = inFlights.filter({ $0.key.tokenID != tokenID })
    }
    
    public func throwAllRequests(error: APIError) async {
        inFlights.forEach({ inFlight in
            inFlight.value.throw(error: error)
        })
        inFlights = [:]
    }
}

private extension APIRequestDispatcher {
    
    func cleanCompletedInFlights() async {
        inFlights = inFlights.filter({ key, value in
            return !value.didComplete
        })
    }
}

final class InFlight {
    
    private(set) var didComplete: Bool = false
    private var cancellables: [AnyCancellable] = []
    private let subject: PassthroughSubject<(Data, URLResponse), Error>
    
    fileprivate init(for publisher: URLSession.DataTaskPublisher) {
        subject = PassthroughSubject()
        publisher
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    guard !self.didComplete else { return }
                    Task.detached(priority: .high) { self.didComplete = true }
                    switch completion {
                    case .finished:
                        self.subject.send(completion: .finished)
                    case .failure(let error):
                        self.subject.send(completion: .failure(error))
                    }
                },
                receiveValue: { [weak self] data, response in
                    guard let self = self else { return }
                    self.subject.send((data, response))
                }
            )
            .store(in: &cancellables)
    }
    
    func attach() async throws -> (Data, URLResponse) {
        return try await withUnsafeThrowingContinuation { continuation in
            subject
                .sink(
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
                )
                .store(in: &cancellables)
        }
    }
    
    func `throw`(error: APIError) {
        subject.send(completion: .failure(error))
        didComplete = true
        cancellables = []
    }
}
