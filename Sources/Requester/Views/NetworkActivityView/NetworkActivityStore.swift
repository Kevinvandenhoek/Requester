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
    var activity: Set<NetworkActivityItem>
    
    private var cancellables: [AnyCancellable] = []
    
    public init(activity: Set<NetworkActivityItem> = []) {
        self.activity = activity
    }
    
    public func setup(with dispatcher: APIRequestDispatching) async {
        await dispatcher.add(delegate: self)
    }
}

extension NetworkActivityStore: APIRequestDispatchingDelegate {
    
    public func requestDispatcher(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskPublisher, for urlRequest: URLRequest) {
        var activity = NetworkActivityItem(urlRequest)
        self.activity.insert(activity)
        
        let updateActivity: (NetworkActivityItem.State) -> Void = { [weak self] state in
            activity.update(to: state)
            self?.activity.insert(activity)
        }
        
        publisher
            .receive(on: DispatchQueue.main)
            .map(NetworkActivityItem.State.succeeded)
            .catch { Just(NetworkActivityItem.State.failed($0)) }
            .sink(receiveValue: updateActivity)
            .store(in: &self.cancellables)
    }
}
