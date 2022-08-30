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
