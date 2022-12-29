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
    public let tokenRefreshDispatcher: TokenRefreshDispatching
    public let urlSessionProvider: URLSessionProviding?
    
    public init(
        urlRequestMapper: URLRequestMapper = URLRequestMapper(),
        dispatcher: APIRequestDispatching = APIRequestDispatcher(),
        memoryCacher: MemoryCaching = MemoryCacher(),
        decoder: DataDecoding = DataDecoder(),
        tokenRefreshDispatcher: TokenRefreshDispatching = TokenRefreshDispatcher(),
        urlSessionProvider: URLSessionProviding? = nil
    ) {
        self.urlRequestMapper = urlRequestMapper
        self.dispatcher = dispatcher
        self.memoryCacher = memoryCacher
        self.decoder = decoder
        self.tokenRefreshDispatcher = tokenRefreshDispatcher
        self.urlSessionProvider = urlSessionProvider
    }
    
    @discardableResult
    public func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        var tokenID: TokenID?
        
        do {
            return try await execute(request, tokenID: &tokenID)
        } catch let error as APIError {
            switch error.type {
            case .invalidToken(let invalidatedTokenID):
                guard let authenticator = request.backend.authenticator else { throw error }
                try await tryTokenRefresh(with: authenticator, tokenID: invalidatedTokenID)
                return try await execute(request, tokenID: &tokenID)
            case .missingToken, .tokenFetchFailure:
                guard let authenticator = request.backend.authenticator else { throw error }
                try await tryTokenRefresh(with: authenticator, tokenID: tokenID)
                return try await execute(request, tokenID: &tokenID)
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
    
    @discardableResult
    public func performWithMemoryCaching<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        return try await performWithMemoryCaching(request, maxCacheLifetime: nil, mapper: { $0 })
    }
    
    @discardableResult
    public func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped {
        return try await performWithMemoryCaching(request, maxCacheLifetime: nil, mapper: mapper)
    }
    
    @discardableResult
    public func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, maxCacheLifetime: TimeInterval?, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped {
        if let cached: Mapped = await memoryCacher.get(request: request, maxLifetime: maxCacheLifetime) {
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
    
    func tryTokenRefresh(with authenticator: Authenticating, tokenID: TokenID?) async throws {
        if let tokenID = tokenID {
            await dispatcher.throwRequests(
                for: tokenID,
                error: APIError(type: .invalidToken(tokenID))
            )
        }
        try await tokenRefreshDispatcher.performTokenRefresh(with: authenticator, tokenID: tokenID)
    }
    
    func execute<Request: APIRequest>(_ request: Request, tokenID: inout TokenID?) async throws -> Request.Response {
        var urlRequest = try urlRequestMapper.map(request)
        
        try request.backend.requestProcessors.forEach { processor in
            try processor.process(&urlRequest)
        }
        
        if let authenticator = request.backend.authenticator {
            switch await authenticator.authenticate(request: &urlRequest) {
            case .success(let usedTokenID):
                tokenID = usedTokenID
            case .failure(.missingToken):
                throw APIError(type: .missingToken)
            }
        }
        
        let urlSession = urlSessionProvider?.urlSession(for: request) ?? URLSession.shared
        let (data, response) = try await dispatcher.dispatch(urlRequest, request, tokenID: tokenID, urlSession: urlSession)
        
        try request.backend.responseProcessors.forEach { processor in
            try processor.process(response, data: data, request: request)
        }
        
        if let httpResponse = response as? HTTPURLResponse,
           let authenticator = request.backend.authenticator {
            if authenticator.shouldRefreshToken(response: httpResponse, data: data) {
                if let tokenID = tokenID {
                    throw APIError(type: .invalidToken(tokenID), statusCode: httpResponse.statusCode)
                } else {
                    throw APIError(type: .missingToken, statusCode: httpResponse.statusCode)
                }
            } else if httpResponse.statusCode == 401 {
                throw APIError(type: .unauthorized, statusCode: httpResponse.statusCode)
            }
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
