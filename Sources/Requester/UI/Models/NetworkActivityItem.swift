//
//  NetworkActivityItem.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI
import Combine

public struct NetworkActivityItem {
    
    public let id: APIRequestDispatchID
    public let date: Date
    public let request: URLRequest
    public var associatedResults: Set<APIRequestingResult>
    public var associatedFollowUps: Set<APIRequestDispatchID>
    public var duration: TimeInterval? { completion?.timeIntervalSince(date) }
    private(set) var completion: Date?
    private(set) var state: State
    
    init(_ request: URLRequest, id: APIRequestDispatchID, state: State = .inProgress, associatedResults: Set<APIRequestingResult> = [], associatedFollowUps: Set<APIRequestDispatchID> = [], completion: Date? = nil) {
        self.id = id
        self.date = Date()
        self.state = state
        self.request = request
        self.associatedResults = associatedResults
        self.associatedFollowUps = associatedFollowUps
        self.completion = completion
    }
    
    public enum State {
        case inProgress
        case failed(URLSession.DataTaskFuture.Failure)
        case succeeded(URLSession.DataTaskFuture.Output)
        
        var id: Int {
            switch self {
            case .inProgress:
                return 0
            case .succeeded:
                return 1
            case .failed:
                return 2
            }
        }
    }
    
    public mutating func update(to state: State) {
        self.state = state
        self.completion = Date()
    }
}

extension NetworkActivityItem {
    
    var statusText: String {
        switch state {
        case .inProgress:
            return "loading"
        case .failed:
            return "failed"
        case .succeeded(let result):
            return String((result.response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
    
    var durationText: String {
        guard let duration, let formatted = numberFormatter.string(for: duration) else { return "" }
        return "\(formatted)s"
    }
    
    var baseUrlText: String {
        guard let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return "nil" }
        return (components.scheme ?? "") + "://" + (components.host ?? "nil")
    }
    
    var pathText: String {
        guard let url = request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return "nil" }
        return String(components.path.dropFirst())
    }
    
    var methodText: String {
        return request.httpMethod ?? ""
    }
    
    var durationColor: Color {
        guard let duration = duration else { return Color.clear }
        if duration >= 4 {
            return Color.red
        } else if duration >= 1 {
            return Color.orange
        } else {
            return Color.subtleText
        }
    }
    
    var issuesText: String {
        let failedSteps = associatedResults.compactMap({ $0.failedStep })
        switch failedSteps.count {
        case 0:
            return "no processing issues"
        case 1:
            return "issue while \(failedSteps[0].description)"
        default:
            return "\(failedSteps.count) issues"
        }
    }
    
    var indicatorColor: Color {
        if associatedResults.contains(where: { $0.failedStep != nil }) {
            return Color.red
        } else {
            switch state {
            case .failed:
                return Color.red
            case .inProgress:
                return Color.blue
            case .succeeded:
                return Color.green
            }
        }
    }
    
    var issuesColor: Color {
        return associatedResults.contains(where: { $0.failedStep != nil })
            ? Color.red
            : Color.subtleText
    }
    
    var statusColor: Color {
        switch state {
        case .inProgress:
            return .blue
        case .failed:
            return .red
        case .succeeded:
            return .green
        }
    }
}

private let numberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    return formatter
}()
