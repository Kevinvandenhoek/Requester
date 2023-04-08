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
    var activity: [UUID: NetworkActivityItem]
    
    private var cancellables: [AnyCancellable] = []
    
    public init(activity: [NetworkActivityItem] = []) {
        self.activity = Dictionary(uniqueKeysWithValues: activity.map { (UUID(), $0) })
    }
    
    public func setup(with dispatcher: APIRequestDispatching) async {
        await dispatcher.add(delegate: self)
    }
}

extension NetworkActivityStore: APIRequestDispatchingDelegate {
    
    public func requestDispatcher(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskPublisher, for urlRequest: URLRequest) {
        let id = UUID()
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
