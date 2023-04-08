//
//  NetworkActivityView.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI

public struct NetworkActivityView: View {
    
    @StateObject var store: NetworkActivityStore
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 30) {
                ForEach(items, id: \.key) { _, value in
                    view(for: value)
                }
            }
            .padding(.all, 25)
        }
        .background(Color(.systemBackground))
    }
}

private extension NetworkActivityView {
    
    var items: [(key: UUID, value: NetworkActivityItem)] {
        return store.activity
            .sorted(by: { $0.value.date < $1.value.date })
    }
    
    func statusText(for activity: NetworkActivityItem) -> String {
        switch activity.state {
        case .inProgress:
            return "loading"
        case .failed:
            return "failed"
        case .succeeded(let result):
            return String((result.response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
    
    func baseUrlText(for activity: NetworkActivityItem) -> String {
        guard let url = activity.request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return "nil" }
        return (components.scheme ?? "") + "://" + (components.host ?? "nil")
    }
    
    func pathText(for activity: NetworkActivityItem) -> String {
        guard let url = activity.request.url,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return "nil" }
        return String(components.path.dropFirst())
    }
    
    func methodText(for activity: NetworkActivityItem) -> String {
        return activity.request.httpMethod ?? ""
    }
}

private extension NetworkActivityView {
    
    @ViewBuilder
    func view(for activity: NetworkActivityItem) -> some View {
        HStack(spacing: 5) {
            description(for: activity)
            Spacer()
            status(for: activity)
        }
    }
    
    @ViewBuilder
    func status(for activity: NetworkActivityItem) -> some View {
        VStack(alignment: .trailing) {
            Text(statusText(for: activity))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color(for: activity.state))
        }
    }
    
    @ViewBuilder
    func description(for activity: NetworkActivityItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(methodText(for: activity) + " | " + baseUrlText(for: activity))
                .font(.system(size: 10, weight: .bold))
                .opacity(0.3)
            Text(pathText(for: activity))
                .font(.system(size: 10, weight: .bold))
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
    
    func color(for status: NetworkActivityItem.State) -> Color {
        switch status {
        case .inProgress:
            return .blue
        case .failed:
            return .red
        case .succeeded:
            return .green
        }
    }
}

#if DEBUG

struct NetworkActivityView_Previews: PreviewProvider {
    
    static let url = URL(string: "https://www.google.com/testing?id=69&time=420")!
    
    static var previews: some View {
        NetworkActivityView(store: NetworkActivityStore(activity: [
            NetworkActivityItem(
                URLRequest(url: url)
            ),
            NetworkActivityItem(
                URLRequest(url: url),
                state: .succeeded((
                    data: Data(),
                    response: HTTPURLResponse(url: url, statusCode: 304, httpVersion: nil, headerFields: [:])!
                ))
            ),
            NetworkActivityItem(
                URLRequest(url: url),
                state: .succeeded((
                    data: Data(),
                    response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
                ))
            ),
            NetworkActivityItem(
                URLRequest(url: url),
                state: .failed(URLSession.DataTaskPublisher.Failure(.badURL))
            )
        ]))
    }
}

#endif
