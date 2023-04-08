//
//  NetworkActivityItem.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation

public struct NetworkActivityItem: Identifiable, Hashable {
    
    public let id: UUID = UUID()
    public let date: Date
    public let request: URLRequest
    private(set) var completion: Date?
    private(set) var state: State
    
    init(_ request: URLRequest, state: State = .inProgress, completion: Date? = nil) {
        self.date = Date()
        self.state = state
        self.request = request
        self.completion = completion
    }
    
    public enum State {
        case inProgress
        case failed(URLSession.DataTaskPublisher.Failure)
        case succeeded(URLSession.DataTaskPublisher.Output)
    }
    
    public mutating func update(to state: State) {
        self.state = state
        self.completion = Date()
    }
    
    public static func == (lhs: NetworkActivityItem, rhs: NetworkActivityItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
