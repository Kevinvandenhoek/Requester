//
//  JSONView.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI

struct JSONView: View {
    
    let title: String?
    let data: Data
    let json: Any
    
    init(title: String? = "JSON", data: Data) {
        self.title = title
        self.data = data
        self.json = data.json as Any
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                if let title {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                }
                HStack {
                    Text("copy")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.subtleText)
                        .onTapGesture {
                            UIPasteboard.general.string = jsonString
                        }
                    Color.subtleText
                        .frame(width: 1.5, height: 11)
                        .padding(.top, 1)
                    Text("copy raw")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.subtleText)
                        .onTapGesture {
                            UIPasteboard.general.string = rawJsonString
                        }
                }
            }
            renderData(json)
        }
        .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private func renderData(_ data: Any) -> some View {
        if let dataDict = json as? [String: Any] {
            ForEach(dataDict.keys.sorted(), id: \.self) { key in
                ExpandableView(key: key, value: dataDict[key]!)
            }
        } else if let dataArray = json as? [Any] {
            ForEach(dataArray.indices, id: \.self) { index in
                ExpandableView(key: "[\(index)]", value: dataArray[index], isExpanded: false)
            }
        } else if let string = String(data: self.data, encoding: .utf8) {
            Text(string)
                .font(.system(size: 12, weight: .bold))
        }
    }
    
    var jsonString: String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .withoutEscapingSlashes]) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }
    
    var rawJsonString: String {
        return String(data: data, encoding: .utf8)
            ?? "Requester.Error: Could not parse data to string for copying"
    }
}

private struct ExpandableView: View {
    @State private var isExpanded: Bool
    let key: String
    let value: Any

    init(key: String, value: Any, isExpanded: Bool = false) {
        self.key = key
        self.value = value
        self._isExpanded = State(initialValue: isExpanded)
    }
    
    var valueText: String? {
        if value as? [String: Any] != nil {
            return nil
        } else if let bool = value as? Bool {
            return String(describing: bool)
        } else if let count = arrayElementCount() {
            return "(\(count))"
        } else {
            return String(describing: value)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                if isExpandable() {
                    withAnimation(.spring(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }) {
                HStack(alignment: .top, spacing: 0) {
                    if isExpandable() {
                        Image(systemName: "chevron.right")
                            .resizable()
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 8, height: 8)
                            .padding(.trailing, 3)
                            .padding(.top, 3.5)
                    } else {
                        Color.clear
                            .frame(width: 8, height: 8)
                            .padding(.trailing, 3)
                    }
                    Text("\(key):")
                        .font(.system(size: 12, weight: .bold))
                    if let valueText {
                        Text(valueText)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.subtleText)
                            .padding(.leading, 4)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                renderValue(value)
                    .padding(.leading, 8)
            }
        }
    }

    func isExpandable() -> Bool {
        return value is [String: Any] || value is [Any]
    }
    
    func arrayElementCount() -> Int? {
        if let array = value as? [Any] {
            return array.count
        } else {
            return nil
        }
    }

    @ViewBuilder
    func renderValue(_ value: Any) -> some View {
        if let valueDict = value as? [String: Any] {
            ForEach(valueDict.keys.sorted(), id: \.self) { key in
                ExpandableView(key: key, value: valueDict[key]!)
            }
        } else if let valueArray = value as? [Any] {
            ForEach(valueArray.indices, id: \.self) { index in
                ExpandableView(key: "[\(index)]", value: valueArray[index], isExpanded: false)
            }
        }
    }
}

#if DEBUG

struct JSONView_Previews: PreviewProvider {
    
    static let json: [String: Any] = [
        "name": "John Doe",
        "age": 30,
        "isStudent": false,
        "modifiable": [
            "breakfast": true,
            "dates": true,
            "guests": true,
            "services": true
          ],
        "address": [
            "business": [
                "city": "New York",
                "country": "USA"
            ],
            "home": [
                "city": "New York",
                "country": "USA"
            ]
        ]
    ]
    
    static var previews: some View {
        ScrollView {
            JSONView(data: try! JSONSerialization.data(withJSONObject: [json, json], options: [.prettyPrinted, .withoutEscapingSlashes]))
        }
    }
}

#endif
