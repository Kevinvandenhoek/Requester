//
//  NetworkActivityStore.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import Combine

@MainActor public final class NetworkActivityStore: ObservableObject {
    
    public static let `default` = NetworkActivityStore()
    
    @Published
    var activity: [APIRequestDispatchID: NetworkActivityItem]
    
    @Published
    var didSetup: Bool = false
    
    @Published
    var showInlineActivity: Bool = UserDefaults.standard.bool(forKey: "Package.Requester.showActivityView")
    
    private var cancellables: [AnyCancellable] = []
    
    public init(activity: [APIRequestDispatchID: NetworkActivityItem] = [:]) {
        self.activity = activity
        $showInlineActivity
            .dropFirst()
            .sink { UserDefaults.standard.set($0, forKey: "Package.Requester.showActivityView") }
            .store(in: &cancellables)
    }
    
    public func setup(with dispatcher: APIRequestDispatching) async {
        await dispatcher.add(delegate: self)
        self.didSetup = true
    }
}

extension NetworkActivityStore: APIRequestDispatchingDelegate {
    
    public func requestDispatcher<Request: APIRequest>(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskFuture, for urlRequest: URLRequest, apiRequest: Request, id: APIRequestDispatchID) {
        DispatchQueue.main.async {
            self.activity[id] = NetworkActivityItem(urlRequest, id: id, name: apiRequest.name)
            
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

public enum APIRequestingStep: Hashable, Sendable {
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
