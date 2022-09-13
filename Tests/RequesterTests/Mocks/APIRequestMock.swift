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
    public let backend: Backend
    public let cachingGroups: [CachingGroup]
    public let method: APIMethod
    public let path: String
    public let decoder: DataDecoding?
    public let validStatusCodes: Set<ClosedRange<Int>>?
    
    public init(parameters: [String: Any] = [:], backend: Backend = BackendMock(), cachingGroups: [CachingGroup] = [], method: APIMethod = .get, path: String = "", decoder: DataDecoding? = nil, validStatusCodes: Set<ClosedRange<Int>>? = nil) {
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
        return try! JSONEncoder().encode(APIRequestResponseMock(id: id))
    }
}

public struct CachingGroupMock: CachingGroup {
    public let id: String
}
