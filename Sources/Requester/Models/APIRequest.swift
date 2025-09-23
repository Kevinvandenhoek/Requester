//
//  APIRequest.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public typealias APIRequestParameters = [String: any Sendable]

public protocol APIRequest: Equatable, Sendable {
    
    associatedtype Response: Decodable & Sendable
    
    /// Used by the network activity monitor if not nil (instead of the path)
    var name: String? { get }
    var parameterEncoding: ParameterEncoding { get }
    var headers: [String: String] { get }
    var method: APIMethod { get }
    var path: String { get }
    var parameters: APIRequestParameters { get }
    var backend: Backend { get }
    var decoder: DataDecoding? { get }
    var cachingGroups: [CachingGroup] { get }
    var statusCodeValidation: StatusCodeValidation { get }
}

// MARK: Defaults
public extension APIRequest {
    
    var name: String? { nil }
    var headers: [String: String] { [:] }
    var parameters: APIRequestParameters { [:] }
    var cachingGroups: [CachingGroup] { [] }
    var decoder: DataDecoding? { nil }
    var parameterEncoding: ParameterEncoding {
        method == .get ? .url() : .json
    }
    var statusCodeValidation: StatusCodeValidation { .default }
}

// MARK: Comparison
public extension APIRequest {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard let lhsParams = lhs.parameters as? [String: NSObject],
              let rhsParams = rhs.parameters as? [String: NSObject] else {
            return false
        }

        return lhs.headers == rhs.headers
            && lhs.backend.baseURL == rhs.backend.baseURL
            && lhs.path == rhs.path
            && NSDictionary(dictionary: lhsParams).isEqual(to: rhsParams)
            && lhs.parameterEncoding == rhs.parameterEncoding
    }
}
