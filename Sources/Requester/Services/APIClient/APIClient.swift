//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIClient {
    
    @discardableResult func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response
}

public actor APIClientService: APIClient {
    
    public let urlRequestMapper: URLRequestMapper
    public let dispatchQueue: APIRequestDispatchQueue
    public let decoder: APIDataDecoder
    
    public init(
        urlRequestMapper: URLRequestMapper = URLRequestMapper(),
        dispatchQueue: APIRequestDispatchQueue = DefaultAPIRequestDispatchQueue(urlSession: URLSession.shared),
        decoder: APIDataDecoder = DefaultAPIDataDecoder()
    ) {
        self.urlRequestMapper = urlRequestMapper
        self.dispatchQueue = dispatchQueue
        self.decoder = decoder
    }
    
    public func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        do {
            return try await execute(request)
        } catch let error as APIError {
            switch error.type {
            case .missingToken, .unauthorized:
                // TODO: Clear relevant requests and put them in the queue
                guard let authenticator = request.backend.authenticator else {
                    throw error
                }
                try await authenticator.refreshToken()
                return try await execute(request)
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
}

private extension APIClientService {
    
    func execute<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        var urlRequest = try urlRequestMapper.map(request)
        
        if let requestProcessor = request.backend.requestProcessor {
            try requestProcessor.process(&urlRequest)
        }
        
        if let authenticator = request.backend.authenticator {
            guard authenticator.authenticate(request: &urlRequest) else {
                throw APIError(type: .missingToken)
            }
        }
        
        let (data, response) = try await dispatchQueue.dispatch(urlRequest, request)
        
        if let responseProcessor = request.backend.responseProcessor {
            try responseProcessor.process(response, data: data, request: request)
        }
        if let httpResponse = response as? HTTPURLResponse,
            let validStatusCodes = request.validStatusCodes,
           !validStatusCodes.contains(where: { range in range.contains(httpResponse.statusCode) }) {
            throw APIError(type: .general, statusCode: httpResponse.statusCode, message: "statuscode did not match validStatusCodes")
        }
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            throw APIError(type: .unauthorized, statusCode: httpResponse.statusCode)
        }
        let decoder = request.decoder ?? self.decoder
        return try decoder.decode(data)
    }
}
