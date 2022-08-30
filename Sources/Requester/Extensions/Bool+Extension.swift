//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

extension Bool {
    
    init?(data: Data) {
        guard let string = String(data: data, encoding: .utf8) else {
            assertionFailure("couldn't cast data")
            return nil
        }
        switch string.lowercased() {
        case "true", "yes", "1":
            self = true
        case "false", "no", "0":
            self = false
        default:
            assertionFailure("couldn't cast \(string.lowercased())")
            return nil
        }
    }
}
