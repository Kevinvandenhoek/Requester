//
//  Data+Extension.swift
//  
//
//  Created by Kevin van den Hoek on 10/04/2023.
//

import Foundation

public extension Data {
    
    var json: Any? {
        return try? JSONSerialization.jsonObject(with: self, options: [])
    }
}
