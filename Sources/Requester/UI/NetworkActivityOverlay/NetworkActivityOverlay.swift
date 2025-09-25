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
    
    @Namespace var namespace
    private let disappearDelay: TimeInterval = 4
    
    public var body: some View {
        VStack(alignment: .trailing) {
            if store.showInlineActivity {
                ForEach(items, id: \.key) { id, item in
                        activityContent(item)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background {
                                #if compiler(>=6.2)
                                if #available(iOS 26.0, *) {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .glassEffect(in: .capsule)
                                } else {
                                    Capsule()
                                        .foregroundColor(Color(.secondarySystemBackground))
                                }
                                #else
                                Capsule()
                                    .foregroundColor(Color(.secondarySystemBackground))
                                #endif
                            }
                            .transition(.move(edge: .bottom))
                            .animation(.easeInOut(duration: 0.2), value: items.map({ $0.key }))
                            .matchedGeometryEffect(id: id, in: namespace)
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.bottom, 60)
        .padding(.trailing, 10)
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
        HStack(spacing: 6) {
            if activity.completion == nil {
                ProgressView()
                    .frame(width: 10, height: 10)
                    .scaleEffect(0.8)
                    .tint(activity.indicatorTextColor)
                    .padding(.trailing, 4)
                    .foregroundStyle(Color.red)
            } else {
                Text(activity.durationText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(activity.indicatorTextColor)
                    .opacity(0.6)
                    .onAppear {
                        Task {
                            guard !hiddenIds.contains(activity.id) else { return }
                            try? await Task.sleep(nanoseconds: UInt64(disappearDelay * 1_000_000_000))
                            self.hiddenIds.insert(activity.id)
                        }
                    }
            }
            Text(activity.name ?? activity.pathText)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(activity.indicatorTextColor)
        }
    }
    
    var items: [(key: APIRequestDispatchID, value: NetworkActivityItem)] {
        return store.activity
            .filter({ id, value in
                if hiddenIds.contains(id) {
                    return false
                } else if let completed = value.completion {
                    return Date().timeIntervalSince(completed) < disappearDelay
                } else {
                    return true
                }
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


#if DEBUG
struct NetworkActivityOverlay_Previews: PreviewProvider {
    
    static var previews: some View {
        NetworkActivityOverlay(NetworkActivityStore.mock())
    }
}
#endif
