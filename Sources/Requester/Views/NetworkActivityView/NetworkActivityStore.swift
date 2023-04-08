//
//  NetworkActivityStore.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import Combine

final class NetworkActivityStore: ObservableObject {
    
    @Published
    var activity: Set<NetworkActivityItem> = []
    
    private var cancellables: [AnyCancellable] = []
    
    init(activity: Set<NetworkActivityItem>) {
        self.activity = activity
    }
    
    func setup(with dispatcher: APIRequestDispatching) async {
        await dispatcher.add(delegate: self)
    }
}

extension NetworkActivityStore: APIRequestDispatchingDelegate {
    
    func requestDispatcher(_ requestDispatcher: APIRequestDispatching, didCreate publisher: URLSession.DataTaskPublisher, for urlRequest: URLRequest) {
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

struct NetworkActivityItem: Identifiable, Hashable {
    
    let id: UUID = UUID()
    let date: Date
    let request: URLRequest
    private(set) var completion: Date?
    private(set) var state: State
    
    init(_ request: URLRequest, state: State = .inProgress, completion: Date? = nil) {
        self.date = Date()
        self.state = state
        self.request = request
        self.completion = completion
    }
    
    enum State {
        case inProgress
        case failed(URLSession.DataTaskPublisher.Failure)
        case succeeded(URLSession.DataTaskPublisher.Output)
    }
    
    mutating func update(to state: State) {
        self.state = state
        self.completion = Date()
    }
    
    static func == (lhs: NetworkActivityItem, rhs: NetworkActivityItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
