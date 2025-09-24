//
//  NetworkActivityDetailView.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI

struct NetworkActivityDetailView: View {
    
    @EnvironmentObject var store: NetworkActivityStore
    
    let item: NetworkActivityItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                section(item.name ?? "Request #\(item.id)") {
                    VStack(alignment: .leading, spacing: 20) {
                        keyValue("URL", item.request.url?.absoluteString)
                        keyValue("Host", item.request.url?.host)
                        keyValue("Path", item.pathText)
                        keyValue("Method", item.request.httpMethod)
                        keyValue("Headers", item.request.allHTTPHeaderFields)
                        requestParameters(for: item.request)
                    }
                }
                section("Response") {
                    VStack(alignment: .leading, spacing: 20) {
                        keyValue("Status", item.statusText)
                        if item.duration != nil {
                            keyValue("Duration", item.durationText)
                        }
                        switch item.state {
                        case .succeeded(let result):
                            responseBody(for: result.data)
                        case .failed(let error):
                            errorSection(for: error)
                        case .inProgress:
                            EmptyView()
                        }
                    }
                }
                section("Usage") {
                    keyValue("Consumers", "\(item.associatedResults.count)")
                }
                if item.associatedResults.contains(where: { $0.failedStep != nil }) {
                    section("Issues") {
                        ForEach(Array(item.associatedResults.filter({ $0.failedStep != nil }))) { result in
                            if let failedStep = result.failedStep {
                                keyValue("Failed step", failedStep.description)
                            }
                            if let error = result.error {
                                errorSection(for: error)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension NetworkActivityDetailView {
    
    var hasParameters: Bool {
        let containsJson: Bool
        if let json = item.request.httpBody?.json {
            if let array = json as? [Any] {
                containsJson = !array.isEmpty
            } else if let dict = json as? [String: Any] {
                containsJson = !dict.isEmpty
            } else {
                containsJson = false
            }
        } else {
            containsJson = false
        }
        let containsQueryItems: Bool
        if let url = item.request.url,
           let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = urlComponents.queryItems {
            containsQueryItems = !queryItems.isEmpty
        } else {
            containsQueryItems = false
        }
        return containsJson || containsQueryItems
    }
}

extension NetworkActivityDetailView {
    
    @ViewBuilder
    func requestParameters(for request: URLRequest) -> some View {
        keyValueView("Parameters") {
            VStack(spacing: 30) {
                if let data = request.httpBody,
                    let json = data.json,
                   ((json as? [Any])?.isEmpty == false || (json as? [String: Any])?.isEmpty == false) {
                    JSONView(data: data)
                }
                if let url = request.url,
                   let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = urlComponents.queryItems,
                   !queryItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("QueryItems")
                            .font(.system(size: 24, weight: .bold))
                        ForEach(queryItems, id: \.name) { queryItem in
                            keyValue(queryItem.name, queryItem.value)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if !hasParameters {
                    Text("No parameters")
                        .font(.system(size: 12))
                        .foregroundColor(Color.subtleText)
                }
            }
            .padding(.all, 8)
            .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(.systemGray6)))
            .padding(.top, 6)
        }
    }
    
    @ViewBuilder
    func responseBody(for data: Data) -> some View {
        keyValueView("Body") {
            ZStack(alignment: .topLeading) {
                if let json = data.json,
                   ((json as? [Any])?.isEmpty == false || (json as? [String: Any])?.isEmpty == false) {
                    JSONView(title: "JSON", data: data)
                } else if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                    Text(text)
                        .font(.system(size: 10))
                } else {
                    Text("No response body")
                        .font(.system(size: 12))
                        .foregroundColor(Color.subtleText)
                }
            }
            .padding(.all, 8)
            .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(.systemGray6)))
            .padding(.top, 6)
        }
    }
    
    @ViewBuilder
    func errorSection(for error: Error) -> some View {
        if let data = deepJSONData(from: error) {
            JSONView(title: "Error", data: data)
                .padding(.all, 8)
                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(.systemGray6)))
                .padding(.top, 6)
        } else {
            keyValue("Error type", String(describing: type(of: error)))
            keyValue("Error description", String(describing: error))
        }
    }
    
    @ViewBuilder
    func section(_ title: String, body: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
            body()
        }
    }
    
    @ViewBuilder
    func keyValueView(_ key: String, _ value: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key)
                .font(.headline)
            value()
        }
    }
    
    @ViewBuilder
    func keyValue(_ key: String, _ value: String?) -> some View {
        keyValueView(key) {
            Text(value ?? "nil")
                .font(.system(size: 12))
        }
    }
    
    @ViewBuilder
    func keyValue(_ key: String, _ value: [String: String]?) -> some View {
        keyValueView(key) {
            VStack(alignment: .leading, spacing: 10) {
                if let headers = value, !headers.isEmpty {
                    ForEach(headers.map({ ($0, $1) }).sorted(by: { $0 < $1 }), id: \.0) { key, value in
                        keyValue(key, value)
                    }
                } else {
                    Text("No headers")
                        .font(.system(size: 12))
                        .foregroundColor(Color.subtleText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.all, 8)
            .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(.systemGray6)))
            .padding(.top, 6)
        }
    }
}

#if DEBUG
struct NetworkActivityDetailView_Previews: PreviewProvider {
    
    static let url = URL(string: "https://www.google.com/testing?id=69&time=420")!
    static let id = 1
    static let request = {
        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "isTestFlight")
        request.setValue("69", forHTTPHeaderField: "id")
        request.setValue("LAB", forHTTPHeaderField: "hotel")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "someJSONItem": 69,
            "someObject": [
                "someId": 420,
                "someKey": "someValue",
            ]
        ], options: [])
        return request
    }()
    
    static var previews: some View {
        NavigationView {
            NetworkActivityDetailView(
                item: NetworkActivityItem(
                    request,
                    id: id,
                    name: nil,
                    state: .succeeded((
                        data: String.largeJSON.toJSON!,
                        response: HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    )),
                    associatedResults: [
                        APIRequestingResult(
                            request: APIRequestMock(),
                            failedStep: .decoding,
                            error: APIError(type: .decoding)
                        )
                    ],
                    completion: Date().addingTimeInterval(4.20)
                )
            )
        }
    }
}

// MARK: - JSON helpers
private func parseJSON(from data: Data) -> Any? {
    try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
}

private func parseJSON(from string: String) -> Any? {
    // try raw
    if let d = string.data(using: .utf8), let obj = parseJSON(from: d) { return obj }
    // try URL-decoded
    if let un = string.removingPercentEncoding,
       let d = un.data(using: .utf8),
       let obj = parseJSON(from: d) { return obj }
    // try unescaping common backslash-escaped quotes (e.g. "{\"a\":1}")
    let unescaped = string
        .replacingOccurrences(of: "\\\"", with: "\"")
        .replacingOccurrences(of: "\\n", with: "\n")
        .replacingOccurrences(of: "\\t", with: "\t")
    if unescaped != string,
       let d = unescaped.data(using: .utf8),
       let obj = parseJSON(from: d) { return obj }
    // try base64 → JSON
    if let d = Data(base64Encoded: string),
       let obj = parseJSON(from: d) { return obj }
    return nil
}

/// Recursively convert ANY Swift value into a JSON-compatible Foundation object.
/// - If a String contains JSON, it is parsed to JSON (recursively).
/// - If Data contains JSON, it's parsed; otherwise it's base64.
/// - Optionals unwrap; collections/dicts/structs/classes/enums are walked recursively.
/// - Falls back to String(describing:) when nothing else fits.
private func toJSONCompatibleDeep(_ value: Any, depth: Int = 0, maxDepth: Int = 6) -> Any? {
    if depth > maxDepth { return String(describing: value) }

    // Optionals
    let mirror = Mirror(reflecting: value)
    if mirror.displayStyle == .optional {
        if let child = mirror.children.first {
            return toJSONCompatibleDeep(child.value, depth: depth, maxDepth: maxDepth)
        } else {
            return NSNull()
        }
    }

    // Primitives & bridged types
    switch value {
    case is NSNull: return NSNull()
    case let s as String:
        // If it *is* JSON, parse it. Otherwise keep the string.
        if let parsed = parseJSON(from: s) {
            return toJSONCompatibleDeep(parsed, depth: depth + 1, maxDepth: maxDepth)
        }
        return s
    case let d as Data:
        if let obj = parseJSON(from: d) {
            return toJSONCompatibleDeep(obj, depth: depth + 1, maxDepth: maxDepth)
        }
        return d.base64EncodedString()
    case let b as Bool: return b
    case let n as NSNumber: return n
    case let i as Int: return i
    case let dbl as Double: return dbl
    case let fl as Float: return fl
    case let date as Date:
        return ISO8601DateFormatter().string(from: date)
    case let url as URL:
        return url.absoluteString
    default: break
    }

    // Already Foundation JSON containers
    if JSONSerialization.isValidJSONObject(value) {
        return value
    }

    // Collections
    switch mirror.displayStyle {
    case .collection, .set:
        return mirror.children.compactMap {
            toJSONCompatibleDeep($0.value, depth: depth + 1, maxDepth: maxDepth)
        }
    case .dictionary:
        var out: [String: Any] = [:]
        for child in mirror.children {
            let pair = Mirror(reflecting: child.value).children.map(\.value)
            guard pair.count == 2 else { continue }
            let key = (pair[0] as? String) ?? String(describing: pair[0])
            if let v = toJSONCompatibleDeep(pair[1], depth: depth + 1, maxDepth: maxDepth) {
                out[key] = v
            }
        }
        return out
    case .struct, .class:
        var out: [String: Any] = [:]
        for child in mirror.children {
            if let label = child.label,
               let v = toJSONCompatibleDeep(child.value, depth: depth + 1, maxDepth: maxDepth) {
                out[label] = v
            }
        }
        // Annotate with type so it’s still readable in your viewer
        out["_type"] = String(describing: type(of: value))
        return out
    case .enum:
        var payload: [Any] = []
        for child in mirror.children {
            if let v = toJSONCompatibleDeep(child.value, depth: depth + 1, maxDepth: maxDepth) {
                payload.append(v)
            }
        }
        return ["_enum": String(describing: value), "associated": payload]
    default:
        break
    }

    // Fallback
    return String(describing: value)
}

/// Try to obtain pretty JSON Data from any value (recursively).
func deepJSONData(from value: Any) -> Data? {
    if let d = value as? Data, parseJSON(from: d) != nil {
        return d
    }
    let obj = toJSONCompatibleDeep(value) ?? "null"
    guard JSONSerialization.isValidJSONObject(obj) else {
        // Wrap non-JSON primitives in a string so JSONView can still render something
        return try? JSONSerialization.data(withJSONObject: ["value": String(describing: obj)],
                                           options: [.prettyPrinted, .sortedKeys])
    }
    return try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
}
#endif
