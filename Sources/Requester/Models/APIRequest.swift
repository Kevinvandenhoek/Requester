//
//  APIRequest.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIRequest: Equatable {
    
    associatedtype Response: Decodable
    
    var parameterEncoding: ParameterEncoding { get }
    var headers: [String: String] { get }
    var method: APIMethod { get }
    var path: String { get }
    var parameters: [String: Any] { get }
    var backend: Backend { get }
    var decoder: DataDecoding? { get }
    var cachingGroups: Set<CachingGroup> { get }
    var statusCodeValidation: StatusCodeValidation { get }
}

// MARK: Defaults
public extension APIRequest {
    
    var headers: [String: String] { [:] }
    var parameters: [String: Any] { [:] }
    var cachingGroups: Set<CachingGroup> { [] }
    var decoder: DataDecoding? { nil }
    var parameterEncoding: ParameterEncoding {
        method == .get ? .url() : .json
    }
    var statusCodeValidation: StatusCodeValidation { .default }
}

// MARK: Comparison
public extension APIRequest {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsDict = lhs.parameters as NSDictionary
        let rhsDict = rhs.parameters as NSDictionary
        return lhs.headers == rhs.headers
            && lhs.backend.baseURL == rhs.backend.baseURL
            && lhs.path == rhs.path
            && lhsDict == rhsDict
            && lhs.parameterEncoding == rhs.parameterEncoding
    }
}
