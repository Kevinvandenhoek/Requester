//
//  APIDataDecoder.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIDataDecoder {
    
    func decode<Value: Decodable>(_ data: Data) throws -> Value
}
