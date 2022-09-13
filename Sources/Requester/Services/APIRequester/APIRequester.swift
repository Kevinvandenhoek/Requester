//
//  APIRequester.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public actor APIRequester: APIRequesting {
    
    public let urlRequestMapper: URLRequestMapper
    public let dispatcher: APIRequestDispatching
    public let decoder: DataDecoding
    
    public init(
        urlRequestMapper: URLRequestMapper = URLRequestMapper(),
        dispatcher: APIRequestDispatching = APIRequestDispatcher(urlSession: URLSession.shared),
        decoder: DataDecoding = DataDecoder()
    ) {
        self.urlRequestMapper = urlRequestMapper
        self.dispatcher = dispatcher
        self.decoder = decoder
    }
    
    @discardableResult
    public func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        do {
            return try await execute(request)
        } catch let error as APIError {
            switch error.type {
            case .missingToken, .unauthorized:
                guard let authenticator = request.backend.authenticator else {
                    throw error
                }
                await authenticator.deleteToken()
                if case .unauthorized(let tokenId) = error.type,
                    let tokenId = tokenId {
                    await dispatcher.throwRequests(
                        for: tokenId,
                        error: APIError(type: .unauthorized(tokenId))
                    )
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

private extension APIRequester {
    
    func execute<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        var urlRequest = try urlRequestMapper.map(request)
        
        if let requestProcessor = request.backend.requestProcessor {
            try requestProcessor.process(&urlRequest)
        }
        
        var tokenID: TokenID?
        if let authenticator = request.backend.authenticator {
            tokenID = await authenticator.authenticate(request: &urlRequest)
            guard tokenID != nil else { throw APIError(type: .missingToken) }
        }
        
        let (data, response) = try await dispatcher.dispatch(urlRequest, request, tokenID: tokenID)
        
        if let responseProcessor = request.backend.responseProcessor {
            try responseProcessor.process(response, data: data, request: request)
        }
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            throw APIError(type: .unauthorized(tokenID), statusCode: httpResponse.statusCode)
        }
        if let httpResponse = response as? HTTPURLResponse,
            let validStatusCodes = request.validStatusCodes,
           !validStatusCodes.contains(where: { range in range.contains(httpResponse.statusCode) }) {
            throw APIError(type: .general, statusCode: httpResponse.statusCode, message: "statuscode did not match validStatusCodes")
        }
        let decoder = request.decoder ?? self.decoder
        return try decoder.decode(data)
    }
}
