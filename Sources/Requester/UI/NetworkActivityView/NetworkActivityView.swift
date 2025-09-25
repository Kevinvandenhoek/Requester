//
//  NetworkActivityView.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI

public struct NetworkActivityView: View {
    
    @EnvironmentObject var store: NetworkActivityStore
    
    public init() { }
    
    public var body: some View {
        NavigationView {
            if store.didSetup || !store.activity.isEmpty {
                if #available(iOS 26, *) {
                    networkActivityList()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Toggle("show inline activity", isOn: $store.showInlineActivity)
                                    .toggleStyle(.switch)
                            }
                            .sharedBackgroundVisibility(.hidden)
                        }
                } else {
                    networkActivityList()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Toggle("show inline activity", isOn: $store.showInlineActivity)
                                    .toggleStyle(.switch)
                            }
                        }
                }
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
    
    func networkActivityList() -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(items, id: \.key) { _, value in
                    view(for: value)
                }
            }
            .padding(.horizontal, 14)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Network Activity")
    }
    
    func idText(for activity: NetworkActivityItem) -> String {
        let activities = [activity.id] + Array(activity
            .associatedFollowUps.sorted(by: { $0 < $1 }))
        return "#\(activities.map({ "\($0)" }).joined(separator: ", #"))"
    }
    
    func timeAgoText(for activity: NetworkActivityItem) -> String {
        let item = activity.associatedFollowUps.compactMap({ store.activity[$0] })
            .sorted(by: { ($0.completion ?? Date.distantPast) < ($1.completion ?? Date.distantPast) })
            .first ?? activity
        guard let finishTime = item.completion else { return "" }
        let timeDifference = Date().timeIntervalSince(finishTime)
        let timeAgoText = dateComponentsFormatter.string(from: timeDifference)
        return timeAgoText.map { "\($0) ago" } ?? ""
    }
    
    var items: [(key: APIRequestDispatchID, value: NetworkActivityItem)] {
        return store.activity
            .filter({ key, value in
                return !appearsInFollowUp(key)
            })
            .sorted(by: { $0.value.date > $1.value.date })
    }
    
    func appearsInFollowUp(_ id: APIRequestDispatchID) -> Bool {
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(idText(for: activity))
                        .font(.system(size: 10))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.leading, 5)
                    Spacer()
                    Text(timeAgoText(for: activity))
                        .font(.system(size: 10))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.trailing, 5)
                }
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
        }
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
                            Text(activity.name ?? activity.pathText)
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
    
    static var previews: some View {
        NetworkActivityView()
            .environmentObject(NetworkActivityStore.mock())
    }
}
#endif

private let dateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "H:mm:ss.SSS"
    return formatter
}()

private let dateComponentsFormatter = {
    let componentsFormatter = DateComponentsFormatter()
    componentsFormatter.allowedUnits = [.second, .minute, .hour, .day, .weekOfMonth, .month, .year]
    componentsFormatter.maximumUnitCount = 2
    componentsFormatter.unitsStyle = .abbreviated
    return componentsFormatter
}()
