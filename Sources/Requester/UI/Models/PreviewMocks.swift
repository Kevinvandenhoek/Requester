//
//  PreviewMocks.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI

#if DEBUG
public struct APIRequestMock: APIRequest {
       
    public typealias Response = APIRequestResponseMock
    
    public let parameters: [String: Any]
    public let backend: Backend
    public let cachingGroups: [CachingGroup]
    public let method: APIMethod
    public let path: String
    public let decoder: DataDecoding?
    public let statusCodeValidation: StatusCodeValidation
    
    public init(parameters: [String: Any] = [:], backend: Backend = .stubbed(), cachingGroups: [CachingGroup] = [], method: APIMethod = .get, path: String = "", decoder: DataDecoding? = nil, statusCodeValidation: StatusCodeValidation? = nil) {
        self.parameters = parameters
        self.backend = backend
        self.cachingGroups = cachingGroups
        self.method = method
        self.path = path
        self.decoder = decoder
        self.statusCodeValidation = statusCodeValidation ?? .default
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

public extension Backend where Self == DefaultBackend {
    
    static func stubbed(
        baseURL: URL = URL(string: "https://www.google.com")!,
        authenticator: Authenticating? = nil,
        requestProcessors: [URLRequestProcessing] = [],
        responseProcessors: [URLResponseProcessing] = []
    ) -> Self {
        return Self(
            baseURL: baseURL,
            authenticator: authenticator,
            requestProcessors: requestProcessors,
            responseProcessors: responseProcessors
        )
    }
}
#endif
