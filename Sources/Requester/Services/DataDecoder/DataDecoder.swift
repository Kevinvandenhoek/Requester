//
//  DataDecoder.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public struct DataDecoder: DataDecoding {
        
    let jsonDecoder: JSONDecoder
    
    public init(jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.jsonDecoder = jsonDecoder
    }
    
    public func decode<Value: Decodable>(_ data: Data) throws -> Value {
        if Value.self == EmptyResponse.self {
            guard let response = EmptyResponse() as? Value else {
                throw APIError(type: .decoding)
            }
            return response
        } else if Value.self == String.self {
            guard let string = String(decoding: data, as: UTF8.self) as? Value else {
                throw APIError(type: .decoding)
            }
            return string
        } else if Value.self == Int.self {
            let string = String(decoding: data, as: UTF8.self)
            guard let int = Int(string) as? Value else {
                throw APIError(type: .decoding)
            }
            return int
        } else if Value.self == Bool.self {
            guard let bool = Bool(data: data) as? Value else {
                throw APIError(type: .decoding)
            }
            return bool
        } else {
            do {
                return try jsonDecoder.decode(Value.self, from: data)
            } catch {
                throw error
            }
        }
    }
}
