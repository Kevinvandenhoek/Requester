//
//  DataDecoding.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol DataDecoding: Sendable {
    
    func decode<Value: Decodable>(_ data: Data) async throws -> Value
}
