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
    
    public init(activity: [APIRequestDispatchID: NetworkActivityItem] = [:]) {
        self.activity = activity
    }
    
    public func setup(with dispatcher: APIRequestDispatching) async {
        await dispatcher.add(delegate: self)
        didSetup = true
    }
}

extension NetworkActivityStore: APIRequestDispatchingDelegate {
    
    public func requestDispatcher(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskPublisher, for urlRequest: URLRequest, id: APIRequestDispatchID) {
        DispatchQueue.main.async {
            self.activity[id] = NetworkActivityItem(urlRequest, id: id)
            
            let updateActivity: (NetworkActivityItem.State) -> Void = { [weak self] state in
                DispatchQueue.main.async {
                    self?.activity[id]?.update(to: state)
                }
            }
            
            publisher
                .receive(on: DispatchQueue.main)
                .map(NetworkActivityItem.State.succeeded)
                .catch { Just(NetworkActivityItem.State.failed($0)) }
                .sink(receiveValue: updateActivity)
                .store(in: &self.cancellables)
        }
    }
}

extension NetworkActivityStore: APIRequestingActivityDelegate {
    
    public func requester(_ requester: APIRequesting, didGetResult result: APIRequestingResult, for id: APIRequestDispatchID) {
        DispatchQueue.main.async {
            self.requester(requester, didGetResult: result, for: id, previous: nil)
        }
    }
    
    public func requester(_ requester: APIRequesting, didGetResult result: APIRequestingResult, for id: APIRequestDispatchID, previous: APIRequestDispatchID?) {
        DispatchQueue.main.async {
            self.activity[id]?.associatedResults.insert(result)
            if let previous {
                self.activity[previous]?.associatedFollowUps.insert(id)
            }
        }
    }
}

public struct APIRequestingResult: Hashable, Identifiable {
    
    public let id = UUID()
    public let request: any APIRequest
    public let failedStep: APIRequestingStep?
    public let error: Error?
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: APIRequestingResult, rhs: APIRequestingResult) -> Bool {
        return lhs.id == rhs.id
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
