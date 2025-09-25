//
//  DataView.swift
//  Requester
//
//  Created by Kevin van den Hoek on 25/09/2025.
//

import SwiftUI

public struct DataView<T>: View {
    let title: String?
    let value: T
    let initiallyExpanded: Bool

    /// If your value conforms to Encodable and you'd like a "Copy JSON" button,
    /// set this to true and pass an Encodable value (or wrap it).
    let enableCopyJSONIfEncodable: Bool

    public init(
        title: String? = nil,
        value: T,
        initiallyExpanded: Bool = true,
        enableCopyJSONIfEncodable: Bool = false
    ) {
        self.title = title
        self.value = value
        self.initiallyExpanded = initiallyExpanded
        self.enableCopyJSONIfEncodable = enableCopyJSONIfEncodable
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                if let title {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                    Spacer(minLength: 8)
                } else {
                    Spacer(minLength: 0)
                }

                // Optional Copy JSON action if the root value is Encodable
                if enableCopyJSONIfEncodable, let encodable = value as? any Encodable {
                    Button {
                        copyJSON(encodable)
                    } label: {
                        Text("Copy JSON")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
            }

            InspectorRow(
                label: title ?? typeName(of: value),
                value: value,
                isRoot: true,
                initiallyExpanded: initiallyExpanded
            )
        }
        .multilineTextAlignment(.leading)
    }

    private func copyJSON(_ encodable: any Encodable) {
        #if canImport(UIKit)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
        if let data = try? encoder.encode(AnyEncodable(encodable)),
           let str = String(data: data, encoding: .utf8) {
            UIPasteboard.general.string = str
        }
        #endif
    }
}

// MARK: - Row

private struct InspectorRow: View {
    let label: String
    let value: Any
    let isRoot: Bool
    @State var isExpanded: Bool
    init(label: String, value: Any, isRoot: Bool = false, initiallyExpanded: Bool = false) {
        self.label = label
        self.value = value
        self.isRoot = isRoot
        self._isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        let node = Node(value)

        VStack(alignment: .leading, spacing: 4) {
            Button {
                if node.isExpandable {
                    withAnimation(.spring(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(alignment: .top, spacing: 4) {
                    if node.isExpandable {
                        Image(systemName: "chevron.right")
                            .resizable()
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 8, height: 8)
                            .padding(.top, 3.5)
                            .foregroundColor(.secondary)
                    } else {
                        Color.clear
                            .frame(width: 8, height: 8)
                            .padding(.top, 3.5)
                    }

                    Text("\(label):")
                        .font(.system(size: 12, weight: .bold))

                    if let inline = node.inlineDescription {
                        Text(inline)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .buttonStyle(.plain)

            if isExpanded, node.isExpandable {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(node.children.enumerated()), id: \.offset) { idx, child in
                        InspectorRow(
                            label: child.label ?? "[\(idx)]",
                            value: child.value,
                            initiallyExpanded: node.defaultChildExpanded
                        )
                    }
                }
                .padding(.leading, 12)
            }
        }
    }
}

// MARK: - Node (reflection helper)

/// A lightweight wrapper around `Mirror` that classifies the value and exposes children for rendering.
private struct Node {
    struct Child {
        let label: String?
        let value: Any
    }

    let value: Any
    let mirror: Mirror
    let style: Mirror.DisplayStyle?
    let typeNameString: String
    let isExpandable: Bool
    let inlineDescription: String?
    let children: [Child]
    let defaultChildExpanded: Bool

    init(_ value: Any) {
        self.value = value
        self.mirror = Mirror(reflecting: value)
        self.style = mirror.displayStyle
        self.typeNameString = typeName(of: value)

        // Build children first so we can decide expandability + inline text
        self.children = Node.computeChildren(value, mirror: mirror)
        self.isExpandable = Node.computeIsExpandable(value, mirror: mirror, children: children)
        self.inlineDescription = Node.inline(value, mirror: mirror, children: children)
        self.defaultChildExpanded = Node.defaultExpanded(for: mirror.displayStyle)
    }

    private static func computeIsExpandable(_ value: Any, mirror: Mirror, children: [Child]) -> Bool {
        if case .optional? = mirror.displayStyle {
            // Expand only if it's .some AND that inner value has children
            if children.count == 1 {
                let inner = Mirror(reflecting: children[0].value)
                return !isInlineScalar(children[0].value, inner)
            }
            return false
        }

        if isInlineScalar(value, mirror) { return false }
        return !children.isEmpty
    }

    private static func isInlineScalar(_ value: Any, _ mirror: Mirror) -> Bool {
        if value is String || value is Substring { return true }
        if value is Bool { return true }
        if value is Int || value is Int8 || value is Int16 || value is Int32 || value is Int64 { return true }
        if value is UInt || value is UInt8 || value is UInt16 || value is UInt32 || value is UInt64 { return true }
        if value is Float || value is Double || value is CGFloat { return true }
        if value is Date { return true }
        if value is URL { return true }
        if value is UUID { return true }

        // enums with no associated values should be inline
        if mirror.displayStyle == .enum, mirror.children.isEmpty {
            return true
        }

        // Data can be huge; treat as inline (length shown)
        if let data = value as? Data {
            return data.count < 64 // small blobs inline; large ones should still be inline but show size
        }

        return false
    }

    private static func inline(_ value: Any, mirror: Mirror, children: [Child]) -> String? {
        switch mirror.displayStyle {
        case .optional:
            if children.isEmpty { return "nil" }
            // Inline description of inner scalar, or short type hint if complex
            let inner = children[0].value
            let innerMirror = Mirror(reflecting: inner)
            if isInlineScalar(inner, innerMirror) {
                return String(describing: inner)
            } else {
                return typeName(of: inner)
            }

        case .collection, .set:
            // e.g. Array (count), Set (count)
            let count = children.count
            return "(\(count) item\(count == 1 ? "" : "s"))"

        case .dictionary:
            let count = children.count
            return "(\(count) pair\(count == 1 ? "" : "s"))"

        case .tuple:
            return "(\(children.count) element\(children.count == 1 ? "" : "s"))"

        case .enum:
            // Show case name + whether there are associated values
            let full = String(describing: value)
            if children.isEmpty {
                return full  // simple enum case
            } else {
                return full  // includes case and associated summary already
            }

        case .struct, .class:
            if children.isEmpty { return typeName(of: value) }
            // Keep it short; type name is nice inline summary
            return typeName(of: value)

        default:
            // Scalars and anything else
            if let data = value as? Data {
                return "Data (\(data.count) bytes)"
            }
            return String(describing: value)
        }
    }

    private static func defaultExpanded(for style: Mirror.DisplayStyle?) -> Bool {
        switch style {
        case .struct, .class: return false
        case .enum:
            return true // Enums are often small; expand by default to show associateds
        case .dictionary, .collection, .set, .tuple: return false
        case .optional: return false
        default: return false
        }
    }

    private static func computeChildren(_ value: Any, mirror: Mirror) -> [Child] {
        switch mirror.displayStyle {
        case .optional:
            // .none => no children; .some => 1 child whose label is "some"
            return mirror.children.map { Child(label: $0.label ?? "some", value: $0.value) }

        case .dictionary:
            // Each child is a key/value tuple
            // We'll render label as "[key]" using a stringified key
            return mirror.children.enumerated().map { (index, element) in
                let pairMirror = Mirror(reflecting: element.value)
                // pairMirror should be a tuple (key, value)
                var keyLabel = "[\(index)]"
                var val: Any = element.value
                if pairMirror.displayStyle == .tuple {
                    // Try to extract .0 (key) and .1 (value)
                    let kv = Array(pairMirror.children)
                    if kv.count == 2 {
                        let keyStr = String(describing: kv[0].value)
                        keyLabel = "[\(keyStr)]"
                        val = kv[1].value
                    }
                }
                return Child(label: keyLabel, value: val)
            }

        case .collection, .set:
            // Label by index
            return mirror.children.enumerated().map { (index, element) in
                Child(label: "[\(index)]", value: element.value)
            }

        case .tuple:
            // Labels are ".0", ".1", ... or may be the tuple element names
            return mirror.children.enumerated().map { (index, element) in
                let raw = element.label ?? ".\(index)"
                let cleaned = raw.hasPrefix(".") ? "[\(index)]" : raw
                return Child(label: cleaned, value: element.value)
            }

        case .enum:
            // Either no children (simple case) or associated values
            // Keep labels as provided; if nil, number them
            let ch = Array(mirror.children)
            if ch.isEmpty { return [] }
            return ch.enumerated().map { (index, element) in
                Child(label: element.label ?? "[\(index)]", value: element.value)
            }

        default:
            // struct/class or anything else — mirror children carry property names
            return mirror.children.enumerated().map { (index, element) in
                Child(label: element.label ?? "[\(index)]", value: element.value)
            }
        }
    }
}

// MARK: - Utilities

private func typeName(of value: Any) -> String {
    let t = type(of: value)
    var name = String(reflecting: t)
    // Trim module names if any ("Module.TypeName" -> "TypeName")
    if let dot = name.split(separator: ".").last {
        name = String(dot)
    }
    return name
}

/// Wrapper to encode an existential `any Encodable`
private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ encodable: any Encodable) {
        _encode = encodable.encode
    }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

// MARK: - Preview / Examples

#if DEBUG
private enum DemoEnum {
    case empty
    case withValue(Int)
    case assoc(label: String, flag: Bool)
}

private struct Address {
    let city: String
    let country: String
}

private struct Person {
    let name: String
    let age: Int
    let isStudent: Bool
    let tags: Set<String>
    let breakfastAllowed: [String: Bool]
    let addresses: [String: Address]
    let favorite: DemoEnum
    let partner: DemoEnum?
    let rawData: Data
}

struct InspectableView_Previews: PreviewProvider {
    static var previews: some View {
        let person = Person(
            name: "John Doe",
            age: 30,
            isStudent: false,
            tags: ["swift", "ios", "dev"],
            breakfastAllowed: ["breakfast": true, "dates": true, "guests": false],
            addresses: [
                "home": Address(city: "New York", country: "USA"),
                "work": Address(city: "New York", country: "USA")
            ],
            favorite: .assoc(label: "hello", flag: true),
            partner: .withValue(7),
            rawData: Data(repeating: 0xAB, count: 12)
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                DataView(title: "Person", value: person, enableCopyJSONIfEncodable: false)
                DataView(title: "Array Example", value: [1, 2, 3, 5, 8, 13], initiallyExpanded: false)
                DataView(title: "Enum Example", value: DemoEnum.withValue(42))
                DataView(title: "Optional nil", value: (nil as String?))
                DataView(title: "Tuple Example", value: (x: 10, y: "hi", z: true))
                DataView(title: "Dictionary Example", value: ["a": 1, "b": 2])
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
            .padding()
        }
    }
}
#endif
