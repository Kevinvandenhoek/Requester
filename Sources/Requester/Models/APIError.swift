//
//  File 2.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public enum APIErrorType: Equatable {
    case general
    case invalidStatusCode
    case unauthorized
    case missingToken
    case tokenFetchFailure
    case invalidToken(TokenID)
    case decoding
}

public struct APIError: Error {
    
    public let type: APIErrorType
    public let statusCode: Int?
    public let underlyingError: Error?
    public let message: String?
    public let urlRequest: URLRequest?
    public let data: Data?
    public let response: URLResponse?
    
    public init(type: APIErrorType, statusCode: Int? = nil, underlyingError: Error? = nil, message: String? = nil, urlRequest: URLRequest? = nil, data: Data? = nil, response: URLResponse? = nil) {
        self.type = type
        self.statusCode = statusCode
        self.underlyingError = underlyingError
        self.message = message
        self.urlRequest = urlRequest
        self.data = data
        self.response = response
    }
}
