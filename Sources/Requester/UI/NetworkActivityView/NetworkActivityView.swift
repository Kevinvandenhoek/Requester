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
        NavigationView {
            if store.didSetup || !store.activity.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(items, id: \.key) { _, value in
                            view(for: value)
                        }
                    }
                    .padding(.all, 14)
                }
                .background(Color(.systemBackground))
                .navigationTitle("Network Activity")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("NetworkActivityStore not set up")
                        .font(.headline)
                    Text("Make sure to call someAPIRequester.setup(with: store)")
                        .font(.caption)
                    Text("For convenience, you can use APIRequester.default.setupNetworkMonitoring() to set up the default APIRequester with the default activity store.")
                        .font(.caption)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .navigationTitle("Network Activity")
                .padding(.all, 17)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }
}

private extension NetworkActivityView {
    
    var items: [(key: APIRequestDispatchID, value: NetworkActivityItem)] {
        return store.activity
            .filter({ key, value in
                return !appearsInFollowUp(key)
            })
            .sorted(by: { $0.value.date < $1.value.date })
    }
    
    func appearsInFollowUp(_ id: UUID) -> Bool {
        return store.activity.contains(where: { _, value in
            return value.associatedFollowUps.contains(id)
        })
    }
    
    func followUps(for activity: NetworkActivityItem) -> [(key: APIRequestDispatchID, value: NetworkActivityItem)] {
        return activity.associatedFollowUps
            .compactMap({ id in
                guard let item = store.activity[id] else { return nil }
                return (key: id, value: item)
            })
            .sorted(by: { $0.value.date < $1.value.date })
    }
}

private extension NetworkActivityView {
    
    @ViewBuilder
    func view(for activity: NetworkActivityItem) -> some View {
        VStack {
            content(for: activity)
            ForEach(followUps(for: activity), id: \.key) { key, value in
                DottedSeparator()
                content(for: value)
            }
        }
        .padding(.all, 5)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .foregroundColor(Color(.systemGray6))
        )
    }
    
    @ViewBuilder
    func content(for activity: NetworkActivityItem) -> some View {
        NavigationLink(
            destination: {
                NetworkActivityDetailView(activity)
                    .environmentObject(store)
            },
            label: {
                HStack(spacing: 5) {
                    Capsule()
                        .foregroundColor(activity.indicatorColor)
                        .frame(width: 3)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(activity.pathText)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color.text)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Text(activity.statusText)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(activity.statusColor)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack(alignment: .top) {
                            Text(activity.methodText)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.subtleText)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Text(activity.issuesText)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(activity.issuesColor)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack(alignment: .top) {
                            Text(activity.baseUrlText)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.subtleText)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Text(activity.durationText)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(activity.durationColor)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text(dateFormatter.string(from: activity.date))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color.subtleText)
                            Spacer()
                            if let completion = activity.completion {
                                Text(dateFormatter.string(from: completion))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.subtleText)
                            }
                        }
                    }
                }
            }
        )
    }
}

#if DEBUG
struct NetworkActivityView_Previews: PreviewProvider {
    
    static let url = URL(string: "https://www.google.com/testing/arieboomsma/nogeenlangerpad/dsfijfdoiigfjod/dfsofdgjdfg?id=69&time=420")!
    
    static let id1 = UUID()
    static let id2 = UUID()
    static let id3 = UUID()
    static let id4 = UUID()
    
    static var previews: some View {
        NetworkActivityView(store: NetworkActivityStore(activity: [
            id1: NetworkActivityItem(
                URLRequest(url: url)
            ),
            id2: NetworkActivityItem(
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
                ],
                associatedFollowUps: [id3],
                completion: Date().addingTimeInterval(4.1345398)
            ),
            id3: NetworkActivityItem(
                URLRequest(url: url),
                state: .succeeded((
                    data: Data(),
                    response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [:])!
                )),
                completion: Date().addingTimeInterval(1.1345398)
            ),
            id4: NetworkActivityItem(
                URLRequest(url: url),
                state: .failed(URLSession.DataTaskPublisher.Failure(.badURL)),
                completion: Date().addingTimeInterval(0.1345398)
            )
        ]))
    }
}
#endif

private let dateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "H:mm:ss.SSS"
    return formatter
}()
