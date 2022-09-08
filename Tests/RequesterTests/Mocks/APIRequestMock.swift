//
//  APIRequestMock.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation
@testable import Requester

public struct APIRequestMock: APIRequest {
       
    public typealias Response = APIRequestResponseMock
    
    public let parameters: [String: Any]
    public let backend: APIBackend
    public let cachingGroups: [APICachingGroup]
    public let method: APIMethod
    public let path: String
    public let decoder: APIDataDecoder?
    public let validStatusCodes: Set<ClosedRange<Int>>?
    
    public init(parameters: [String: Any] = [:], backend: APIBackend = APIBackendMock(), cachingGroups: [APICachingGroup] = [], method: APIMethod = .get, path: String = "", decoder: APIDataDecoder? = nil, validStatusCodes: Set<ClosedRange<Int>>? = nil) {
        self.parameters = parameters
        self.backend = backend
        self.cachingGroups = cachingGroups
        self.method = method
        self.path = path
        self.decoder = decoder
        self.validStatusCodes = validStatusCodes
    }
}

public struct APIRequestResponseMock: Codable, Equatable {
    public let id: String
    
    var toData: Data {
        return withUnsafePointer(to: self) { p in
            Data(bytes: p, count: MemoryLayout.size(ofValue: self))
        }
    }
}

public struct APICachingGroupMock: APICachingGroup {
    public let id: String
}
