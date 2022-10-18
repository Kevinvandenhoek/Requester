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
    public let memoryCacher: MemoryCaching
    public let decoder: DataDecoding
    
    public init(
        urlRequestMapper: URLRequestMapper = URLRequestMapper(),
        dispatcher: APIRequestDispatching = APIRequestDispatcher(urlSession: URLSession.shared),
        memoryCacher: MemoryCaching = MemoryCacher(),
        decoder: DataDecoding = DataDecoder()
    ) {
        self.urlRequestMapper = urlRequestMapper
        self.dispatcher = dispatcher
        self.memoryCacher = memoryCacher
        self.decoder = decoder
    }
    
    @discardableResult
    public func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        do {
            return try await execute(request)
        } catch {
            switch (error as? APIError)?.type {
            case .missingToken:
                guard let authenticator = request.backend.authenticator,
                      authenticator.shouldRefreshTokenOn401 else { throw error }
                
                try await authenticator.fetchToken()
                return try await execute(request)
            case .unauthorized(let tokenID):
                guard let tokenID = tokenID,
                      let authenticator = request.backend.authenticator,
                      authenticator.shouldRefreshTokenOn401 else { throw error }
                
                await authenticator.deleteToken(with: tokenID)
                await dispatcher.throwRequests(
                    for: tokenID,
                    error: APIError(type: .unauthorized(tokenID))
                )
                try await authenticator.fetchToken()
                return try await execute(request)
            default:
                throw error
            }
        }
    }
    
    @discardableResult
    public func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped {
        return try await performWithMemoryCaching(request, maxCacheLifetime: nil, mapper: mapper)
    }
    
    @discardableResult
    public func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, maxCacheLifetime: TimeInterval?, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped {
        if let cached: Mapped = await memoryCacher.get(request: request, maxLifetime: maxCacheLifetime ?? .greatestFiniteMagnitude) {
            return cached
        } else {
            let response = try await perform(request)
            let mapped = try mapper(response)
            await memoryCacher.store(request: request, model: mapped)
            return mapped
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
            switch await authenticator.authenticate(request: &urlRequest) {
            case .success(let usedTokenID):
                tokenID = usedTokenID
            case .failure(.missingToken):
                throw APIError(type: .missingToken)
            }
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
