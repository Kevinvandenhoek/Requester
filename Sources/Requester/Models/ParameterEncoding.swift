//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public enum ParameterEncoding {
    case json
    case url(destination: URLEncodingDestination? = nil)
    case urlAndJson(urlKeys: [String])
    case jsonArray
    case custom(ParameterEncoder)
}

public typealias ParameterEncoder = (_ parameters: [String: Any], _ request: inout URLRequest) -> Void

public extension ParameterEncoding {
    
    static var jsonArrayKey: String { "jsonArrayKey" }
}

public enum URLEncodingDestination {
    case body
    case queryString
    
    static func `default`(for method: APIMethod) -> URLEncodingDestination {
        switch method {
        case .get, .put, .delete:
            return .queryString
        case .post, .patch: // TODO: Double check if body is the correct default destination for a patch apimethod
            return .body
        }
    }
}
