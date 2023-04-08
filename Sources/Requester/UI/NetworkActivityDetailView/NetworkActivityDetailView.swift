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
                section("Request") {
                    VStack(alignment: .leading, spacing: 20) {
                        keyValue("URL", item.request.url?.absoluteString)
                        keyValue("Host", item.request.url?.host)
                        keyValue("Path", item.pathText)
                        keyValue("Method", item.request.httpMethod)
                        keyValue("Headers", item.request.allHTTPHeaderFields)
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
                            responseBody(for: result)
                        case .failed(let error):
                            errorSection(for: error)
                        case .inProgress:
                            EmptyView()
                        }
                    }
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
            .padding(.all, 25)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension NetworkActivityDetailView {
    
    @ViewBuilder
    func responseBody(for output: URLSession.DataTaskPublisher.Output) -> some View {
        keyValueView("Body") {
            Text("some body")
//            Text(output.data.formattedText)
                .font(.system(size: 10))
                .padding(.all, 10)
                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(.systemGray6)))
                .padding(.top, 6)
                .onTapGesture {
                    UIPasteboard.general.string = output.data.formattedText
                }
        }
    }
    
    @ViewBuilder
    func errorSection(for error: Error) -> some View {
        keyValue("Error type", String(describing: type(of: error)))
        keyValue("Error description", String(describing: error))
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
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach((value ?? [:]).map({ $0.key }), id: \.self) { value in
                        HStack(alignment: .center) {
                            Text(value)
                                .font(.system(size: 12))
                            DottedSeparator(height: 2)
                        }
                    }
                }
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach((value ?? [:]).map({ $0.value }), id: \.self) { value in
                        Text(value)
                            .font(.system(size: 12))
                    }
                }
            }
            .padding(.top, 2)
        }
    }
}

#if DEBUG
struct NetworkActivityDetailView_Previews: PreviewProvider {
    
    static let jsonString = """
    {"widget": {
        "debug": "on",
        "window": {
            "title": "Sample Konfabulator Widget",
            "name": "main_window",
            "width": 500,
            "height": 500
        },
        "image": {
            "src": "Images/Sun.png",
            "name": "sun1",
            "hOffset": 250,
            "vOffset": 250,
            "alignment": "center"
        },
        "text": {
            "data": "Click Here",
            "size": 36,
            "style": "bold",
            "name": "text1",
            "hOffset": 250,
            "vOffset": 100,
            "alignment": "center",
            "onMouseUp": "sun1.opacity = (sun1.opacity / 100) * 90;"
        }
    }}
    """
    
    static let url = URL(string: "https://www.google.com/testing?id=69&time=420")!
    static let id = UUID()
    static let request = {
        var request = URLRequest(url: url)
        request.setValue("true", forHTTPHeaderField: "isTestFlight")
        request.setValue("69", forHTTPHeaderField: "id")
        request.setValue("LAB", forHTTPHeaderField: "hotel")
        return request
    }()
    
    static var previews: some View {
        NavigationView {
            NetworkActivityDetailView(
                item: NetworkActivityItem(
                    request,
                    state: .succeeded((
                        data: jsonString.jsonData()!,
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

private extension Data {
    
    var formattedText: String {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes]),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return String(decoding: self, as: UTF8.self)
        }
        return jsonString
    }
}

private extension String {
    func jsonData() -> Data? {
        guard let data = self.data(using: .utf8) else { return nil }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        return try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
    }
}
#endif
