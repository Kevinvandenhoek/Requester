//
//  JSONView.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI

struct JSONView: View {
    let json: Any

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("JSON")
                    .font(.system(size: 24, weight: .bold))
                Spacer()
                Text("copy")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.subtleText)
                    .onTapGesture {
                        UIPasteboard.general.string = jsonString
                    }
            }
            renderData(json)
        }
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
        }
    }
    
    var jsonString: String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .withoutEscapingSlashes])
            return String(data: jsonData, encoding: .utf8) ?? "\(json)"
        } catch {
            print("Error converting value to JSON string: \(error.localizedDescription)")
            return "\(json)"
        }
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

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                if isExpandable() {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 0) {
                    if isExpandable() {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .resizable()
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
                    if !isExpandable() {
                        Text(String(describing: value))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.subtleText)
                            .padding(.leading, 4)
                    } else if let count = arrayElementCount() {
                        Text("(\(count))")
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

private extension [String: Any] {
    var toJSONString: String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes]) {
            return String(data: jsonData, encoding: .utf8) ?? "bad json"
        } else {
            return "bad json"
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
            JSONView(json: [json, json])
                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(.systemGray6)))
        }
    }
}

#endif
