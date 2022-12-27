//
//  APIRequest.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIRequest: Equatable {
    
    associatedtype Response: Decodable
    
    var validStatusCodes: Set<ClosedRange<Int>>? { get }
    var parameterEncoding: ParameterEncoding { get }
    var headers: [String: String] { get }
    var method: APIMethod { get }
    var path: String { get }
    var parameters: [String: Any] { get }
    var backend: Backend { get }
    var decoder: DataDecoding? { get }
    var cachingGroups: [CachingGroup] { get }
}

// MARK: Defaults
public extension APIRequest {
    
    var validStatusCodes: Set<ClosedRange<Int>>? { nil }
    var headers: [String: String] { [:] }
    var parameters: [String: Any] { [:] }
    var cachingGroups: [CachingGroup] { [] }
    var decoder: DataDecoding? { nil }
    var parameterEncoding: ParameterEncoding {
        method == .get ? .url() : .json
    }
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
