//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public enum ParameterEncoding: Equatable {
    case json
    case url(destination: URLEncodingDestination? = nil)
    case urlAndJson(urlKeys: [String])
    case jsonArray
    case custom(ParameterEncoder)
}

public typealias ParameterEncoder = (_ parameters: [String: Any], _ request: inout URLRequest) -> Void

public extension ParameterEncoding {
    
    static var jsonArrayKey: String { "jsonArrayKey" }
    
    static func == (lhs: ParameterEncoding, rhs: ParameterEncoding) -> Bool {
        switch lhs {
        case .json:
            if case .json = rhs {
                return true
            } else {
                return false
            }
        case .url(let lhsDestination):
            if case .url(let rhsDestination) = rhs {
                return lhsDestination == rhsDestination
            } else {
                return false
            }
        case .urlAndJson(let lhsUrlKeys):
            if case .urlAndJson(let rhsUrlKeys) = rhs {
                return lhsUrlKeys == rhsUrlKeys
            } else {
                return false
            }
        case .jsonArray:
            if case .jsonArray = rhs {
                return true
            } else {
                return false
            }
        case .custom(let lhsEncoder):
            if case .custom(let rhsEncoder) = rhs {
                var lhsRequest = URLRequest(url: URL(string: "https://www.test.com")!)
                var rhsRequest = URLRequest(url: URL(string: "https://www.test.com")!)
                lhsEncoder(["key":"value"], &lhsRequest)
                rhsEncoder(["key":"value"], &rhsRequest)
                return lhsRequest == rhsRequest
            } else {
                return false
            }
        }
    }
}

public enum URLEncodingDestination {
    case body
    case queryString
    
    static func `default`(for method: APIMethod) -> URLEncodingDestination {
        switch method {
        case .get, .put, .delete:
            return .queryString
        case .post, .patch:
            return .body
        }
    }
}
