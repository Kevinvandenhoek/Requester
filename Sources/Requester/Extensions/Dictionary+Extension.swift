//
//  Dictionary+Extension.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public extension Dictionary {
    
    var percentEncoded: Data? {
        let value = compactMap { key, value in
                guard let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed),
                      !escapedKey.isEmpty,
                      let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed),
                      !escapedValue.isEmpty else { return nil }
                return escapedKey + "=" + escapedValue
            }
            .joined(separator: "&")
            .data(using: .utf8)
        return value
    }
    
    func asyncFilter(_ predicate: @escaping (Key, Value) async -> Bool) async -> [Key: Value] {
        var filteredDictionary: [Key: Value] = [:]
        await withTaskGroup(of: (key: Key, value: Value)?.self) { group in
            for (key, value) in self {
                group.addTask {
                    let shouldInclude = await predicate(key, value)
                    return shouldInclude ? (key: key, value: value) : nil
                }
            }

            for await result in group {
                if let result = result {
                    filteredDictionary[result.key] = result.value
                }
            }
        }
        return filteredDictionary
    }
}

private extension CharacterSet {
    
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
