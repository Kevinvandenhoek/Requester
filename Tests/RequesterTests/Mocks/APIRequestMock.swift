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
    
    public init(parameters: [String: Any] = [:], backend: APIBackend = APIBackendMock(), cachingGroups: [APICachingGroup] = [], method: APIMethod = .get, path: String = "", decoder: APIDataDecoder? = nil) {
        self.parameters = parameters
        self.backend = backend
        self.cachingGroups = cachingGroups
        self.method = method
        self.path = path
        self.decoder = decoder
    }
}

public struct APIRequestResponseMock: Codable, Equatable {
    public let id: String
}

public struct APICachingGroupMock: APICachingGroup {
    public let id: String
}
