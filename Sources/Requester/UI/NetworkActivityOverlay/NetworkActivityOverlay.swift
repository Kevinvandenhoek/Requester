//
//  NetworkActivityOverlay.swift
//  
//
//  Created by Kevin van den Hoek on 09/06/2023.
//

import Foundation
import SwiftUI

public struct NetworkActivityOverlay: View {
    
    @StateObject
    var store: NetworkActivityStore
    
    @State
    var showActivityView: Bool = false
    
    @State
    var hiddenIds: Set<APIRequestDispatchID> = []
    
    public var body: some View {
        VStack {
            Spacer()
            if store.showInlineActivity {
                ForEach(items, id: \.key) { id, item in
                    HStack {
                        Spacer()
                        activityContent(item)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 10)
                            .background(SingleRoundedCapsule()
                                .foregroundColor(Color(.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, y: 3)
                            )
                            .transition(.move(edge: .bottom))
                            .animation(.easeInOut(duration: 0.2))
                            .id(id)
                    }
                }
            }
        }
        .padding(.bottom, 10)
        .sheet(isPresented: $showActivityView) {
            NetworkActivityView()
                .environmentObject(store)
        }
        .onShake {
            showActivityView.toggle()
        }
    }
}

private extension NetworkActivityOverlay {
    
    @ViewBuilder
    func activityContent(_ activity: NetworkActivityItem) -> some View {
        HStack(spacing: 8) {
            if activity.completion == nil {
                ProgressView()
                    .frame(width: 10, height: 10)
                    .padding(.trailing, 4)
            } else {
                Circle()
                    .foregroundColor(activity.indicatorColor)
                    .frame(width: 5, height: 5)
                    .padding(.leading, 2)
                Text(activity.durationText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(activity.indicatorColor)
                    .onAppear {
                        Task {
                            guard !hiddenIds.contains(activity.id) else { return }
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            self.hiddenIds.insert(activity.id)
                        }
                    }
            }
            Text(activity.pathText)
                .font(.system(size: 10, weight: .bold))
        }
    }
    
    var items: [(key: APIRequestDispatchID, value: NetworkActivityItem)] {
        return store.activity
            .filter({ id, _ in
                return !hiddenIds.contains(id)
            })
            .sorted(by: { $0.value.date < $1.value.date })
    }
}

// MARK: Shake gesture helpers
private extension View {
    @ViewBuilder
    func onShake(if condition: Bool = true, perform action: @escaping () -> Void) -> some View {
        if condition {
            self.modifier(DeviceShakeViewModifier(action: action))
        } else {
            self
        }
    }
}

private extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
    }
}

private struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

private struct SingleRoundedCapsule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let radius = min(rect.size.width, rect.size.height) / 2
        
        let startPoint = CGPoint(x: rect.minX + radius, y: rect.minY)
        path.move(to: startPoint)
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.midY), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}
