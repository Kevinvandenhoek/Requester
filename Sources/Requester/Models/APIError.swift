//
//  File 2.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public enum APIErrorType: String {
    case general
    case unauthorized
    case missingToken
    case tokenFetchFailure
    case decoding
}

public struct APIError: Error {
    
    public let type: APIErrorType
    public let statusCode: Int?
    public let underlyingError: Error?
    public let message: String?
    
    public init(type: APIErrorType, statusCode: Int? = nil, underlyingError: Error? = nil, message: String? = nil) {
        self.type = type
        self.statusCode = statusCode
        self.underlyingError = underlyingError
        self.message = message
    }
}
