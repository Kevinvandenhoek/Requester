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
        if store.didSetup {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(items, id: \.key) { _, value in
                        view(for: value)
                    }
                }
                .padding(.all, 25)
            }
            .background(Color(.systemBackground))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("NetworkActivityStore not set up")
                    .font(.headline)
                Text("Make sure to call someAPIRequester.setup(with: store)")
                    .font(.caption)
                Text("For convenience, you can use APIRequester.default.setupNetworkMonitoring() to set up the default APIRequester with the default activity store.")
                    .font(.caption)
            }
            .padding(.all, 25)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
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
    
    func issuesText(for activity: NetworkActivityItem) -> String {
        let failedSteps = activity.associatedResults.compactMap({ $0.failedStep })
        switch failedSteps.count {
        case 0:
            return "no processing issues"
        case 1:
            return "issue while \(failedSteps[0].description)"
        default:
            return "\(failedSteps.count) issues"
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
            Capsule()
                .foregroundColor(indicatorColor(for: activity))
                .frame(width: 3)
            description(for: activity)
            Spacer()
            status(for: activity)
        }
        .padding(.all, 5)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .foregroundColor(Color(.systemGray6))
        )
    }
    
    func indicatorColor(for activity: NetworkActivityItem) -> Color {
        if activity.associatedResults.contains(where: { $0.failedStep != nil }) {
            return Color.red
        } else {
            switch activity.state {
            case .failed:
                return Color.red
            case .inProgress:
                return Color.blue
            case .succeeded:
                return Color.green
            }
        }
    }
    
    @ViewBuilder
    func status(for activity: NetworkActivityItem) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text(statusText(for: activity))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(statusColor(for: activity.state))
            Text(issuesText(for: activity))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(issuesColor(for: activity))
        }
    }
    
    @ViewBuilder
    func description(for activity: NetworkActivityItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(pathText(for: activity))
                .font(.system(size: 10, weight: .bold))
            Text(methodText(for: activity) + " | " + baseUrlText(for: activity))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(.systemGray2))
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
    
    func issuesColor(for item: NetworkActivityItem) -> Color {
        return item.associatedResults.contains(where: { $0.failedStep != nil })
            ? Color.red
            :  Color(.systemGray2)
    }
    
    func statusColor(for status: NetworkActivityItem.State) -> Color {
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
                )),
                associatedResults: [
                    APIRequestingResult(
                        request: APIRequestMock(),
                        failedStep: .dispatching,
                        error: APIError(type: .general)
                    ),
                    APIRequestingResult(
                        request: APIRequestMock(),
                        failedStep: nil,
                        error: nil
                    )
                ]
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

public struct APIRequestMock: APIRequest {
       
    public typealias Response = APIRequestResponseMock
    
    public let parameters: [String: Any]
    public let backend: Backend
    public let cachingGroups: [CachingGroup]
    public let method: APIMethod
    public let path: String
    public let decoder: DataDecoding?
    public let statusCodeValidation: StatusCodeValidation
    
    public init(parameters: [String: Any] = [:], backend: Backend = .stubbed(), cachingGroups: [CachingGroup] = [], method: APIMethod = .get, path: String = "", decoder: DataDecoding? = nil, statusCodeValidation: StatusCodeValidation? = nil) {
        self.parameters = parameters
        self.backend = backend
        self.cachingGroups = cachingGroups
        self.method = method
        self.path = path
        self.decoder = decoder
        self.statusCodeValidation = statusCodeValidation ?? .default
    }
}

public struct APIRequestResponseMock: Codable, Equatable {
    public let id: String
    
    var toData: Data {
        return try! JSONEncoder().encode(APIRequestResponseMock(id: id))
    }
}

public struct CachingGroupMock: CachingGroup {
    public let id: String
}

public extension Backend where Self == DefaultBackend {
    
    static func stubbed(
        baseURL: URL = URL(string: "https://www.google.com")!,
        authenticator: Authenticating? = nil,
        requestProcessors: [URLRequestProcessing] = [],
        responseProcessors: [URLResponseProcessing] = []
    ) -> Self {
        return Self(
            baseURL: baseURL,
            authenticator: authenticator,
            requestProcessors: requestProcessors,
            responseProcessors: responseProcessors
        )
    }
}
#endif
