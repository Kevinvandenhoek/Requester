//
//  NetworkActivityStore.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import Combine

public final class NetworkActivityStore: ObservableObject {
    
    public static let `default` = NetworkActivityStore()
    
    @Published
    var activity: [APIRequestDispatchID: NetworkActivityItem]
    
    @Published
    var didSetup: Bool = false
    
    private var cancellables: [AnyCancellable] = []
    
    public init(activity: [NetworkActivityItem] = []) {
        self.activity = Dictionary(uniqueKeysWithValues: activity.map { (UUID(), $0) })
    }
    
    public func setup(with dispatcher: APIRequestDispatching) async {
        await dispatcher.add(delegate: self)
        didSetup = true
    }
}

extension NetworkActivityStore: APIRequestDispatchingDelegate {
    
    public func requestDispatcher(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskPublisher, for urlRequest: URLRequest, id: APIRequestDispatchID) {
        var activity = NetworkActivityItem(urlRequest)
        self.activity[id] = activity
        
        let updateActivity: (NetworkActivityItem.State) -> Void = { [weak self] state in
            activity.update(to: state)
            self?.activity[id] = activity
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .map(NetworkActivityItem.State.succeeded)
            .catch { Just(NetworkActivityItem.State.failed($0)) }
            .sink(receiveValue: updateActivity)
            .store(in: &self.cancellables)
    }
}

extension NetworkActivityStore: APIRequestingActivityDelegate {
    
    public func requester(_ requester: APIRequesting, didGetResult result: APIRequestingResult, for id: APIRequestDispatchID) {
        activity[id]?.associatedResults.insert(result)
    }
}

public struct APIRequestingResult: Hashable {
    
    let request: any APIRequest
    let failedStep: APIRequestingStep?
    let error: Error?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(HashableAPIRequest(from: request))
        hasher.combine(failedStep)
    }
    
    public static func == (lhs: APIRequestingResult, rhs: APIRequestingResult) -> Bool {
        return HashableAPIRequest(from: lhs.request) == HashableAPIRequest(from: rhs.request)
            && lhs.failedStep == rhs.failedStep
    }
}

public enum APIRequestingStep: Hashable {
    case dispatching
    case processing
    case authorizationValidation
    case statusCodeValidation
    case decoding
    case mapping
    
    var description: String {
        switch self {
        case .dispatching:
            return "dispatching"
        case .processing:
            return "processing"
        case .authorizationValidation:
            return "validating authorization"
        case .statusCodeValidation:
            return "validating status code"
        case .decoding:
            return "decoding"
        case .mapping:
            return "mapping"
        }
    }
}
