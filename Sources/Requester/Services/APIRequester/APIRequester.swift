//
//  APIRequester.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public actor APIRequester: APIRequesting {
    
    #if DEBUG
    public static let `default` = APIRequester(enableNetworkMonitoring: true)
    #else
    public static let `default` = APIRequester()
    #endif
    
    public let urlRequestMapper: URLRequestMapper
    public let dispatcher: APIRequestDispatching
    public let memoryCacher: MemoryCaching
    public let decoder: DataDecoding
    public let tokenRefreshDispatcher: TokenRefreshDispatching
    public let sslPinner: SSLPinning
    
    private let urlSessionManager: URLSessionManaging
    private let urlSessionDelegate = URLSessionDelegateWrapper()
    
    private var stores: [() -> NetworkActivityStore?] = []
    
    public init(
        urlRequestMapper: URLRequestMapper = URLRequestMapper(),
        dispatcher: APIRequestDispatching = APIRequestDispatcher(),
        memoryCacher: MemoryCaching = MemoryCacher(),
        decoder: DataDecoding = DataDecoder(),
        tokenRefreshDispatcher: TokenRefreshDispatching = TokenRefreshDispatcher(),
        urlSessionConfigurationProvider: URLSessionConfigurationProviding = URLSessionConfigurationProvider(),
        sslPinner: SSLPinning = SSLPinner(),
        enableNetworkMonitoring: Bool = false
    ) {
        self.urlRequestMapper = urlRequestMapper
        self.dispatcher = dispatcher
        self.memoryCacher = memoryCacher
        self.decoder = decoder
        self.tokenRefreshDispatcher = tokenRefreshDispatcher
        self.urlSessionManager = URLSessionManager(urlSessionConfigurationProvider: urlSessionConfigurationProvider, delegate: urlSessionDelegate)
        self.sslPinner = sslPinner
        
        Task {
            await sslPinner.setup(with: urlSessionDelegate)
            if enableNetworkMonitoring {
                await setupActivityMonitoring()
            }
        }
    }
    
    @discardableResult
    public func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        return try await perform(request, mapper: { $0 })
    }
    
    @discardableResult
    public func perform<Request: APIRequest, Mapped>(_ request: Request, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped {
        var tokenID: TokenID?
        var dispatchId: APIRequestDispatchID?
        do {
            return try await execute(
                request,
                tokenID: &tokenID,
                dispatchId: &dispatchId,
                previous: nil,
                mapper: mapper
            )
        } catch let error as APIError {
            switch error.type {
            case .invalidToken(let invalidatedTokenID):
                let previous = dispatchId
                guard let authenticator = request.backend.authenticator else { throw error }
                try await tryTokenRefresh(with: authenticator, tokenID: invalidatedTokenID)
                return try await execute(
                    request,
                    tokenID: &tokenID,
                    dispatchId: &dispatchId,
                    previous: previous,
                    mapper: mapper
                )
            case .missingToken, .tokenFetchFailure:
                let previous = dispatchId
                guard let authenticator = request.backend.authenticator else { throw error }
                try await tryTokenRefresh(with: authenticator, tokenID: tokenID)
                return try await execute(
                    request,
                    tokenID: &tokenID,
                    dispatchId: &dispatchId,
                    previous: previous,
                    mapper: mapper
                )
            default:
                throw error
            }
        } catch {
            throw error
        }
    }
    
    @discardableResult
    public func perform<Request: APIRequest>(_ request: Request, cacheLifetime: CacheLifetime) async throws -> Request.Response {
        return try await perform(
            request,
            cacheLifetime: cacheLifetime,
            mapper: { $0 }
        )
    }
    
    @discardableResult
    public func perform<Request: APIRequest, Mapped>(_ request: Request, cacheLifetime: CacheLifetime, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped {
        if let cached: Mapped = await memoryCacher.get(request: request, maxLifetime: cacheLifetime) {
            return cached
        } else {
            let mapped = try await perform(request, mapper: mapper)
            await memoryCacher.store(request: request, model: mapped)
            return mapped
        }
    }
    
    public func setup(with store: NetworkActivityStore) async {
        await store.setup(with: dispatcher)
        stores.append { [weak store] in store }
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
    
    func execute<Request: APIRequest, Mapped>(_ request: Request, tokenID: inout TokenID?, dispatchId: inout APIRequestDispatchID?, previous: APIRequestDispatchID?, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped {
        var urlRequest = try urlRequestMapper.map(request)
        
        for processor in request.backend.requestProcessors {
            try await processor.process(&urlRequest)
        }
        
        if let authenticator = request.backend.authenticator {
            switch await authenticator.authenticate(request: &urlRequest) {
            case .success(let usedTokenID):
                tokenID = usedTokenID
            case .failure(.missingToken):
                throw APIError(type: .missingToken, urlRequest: urlRequest)
            }
        }
        
        let urlSession = await urlSessionManager.urlSession(for: request)
        var step: APIRequestingStep = .dispatching
        do {
            let (data, response) = try await dispatcher.dispatch(urlRequest, request, tokenID: tokenID, urlSession: urlSession, dispatchId: &dispatchId)
            
            step = .processing
            for processor in request.backend.responseProcessors {
                try await processor.process(response, data: data, request: request)
            }
            
            step = .authorizationValidation
            if let httpResponse = response as? HTTPURLResponse,
               let authenticator = request.backend.authenticator {
                if await authenticator.shouldRefreshToken(request: request, response: httpResponse, data: data) {
                    if let tokenID = tokenID {
                        throw APIError(
                            type: .invalidToken(tokenID),
                            statusCode: httpResponse.statusCode,
                            urlRequest: urlRequest,
                            data: data,
                            response: response
                        )
                    } else {
                        throw APIError(
                            type: .missingToken,
                            statusCode: httpResponse.statusCode,
                            urlRequest: urlRequest,
                            data: data,
                            response: response
                        )
                    }
                } else if httpResponse.statusCode == 401 {
                    throw APIError(
                        type: .unauthorized,
                        statusCode: httpResponse.statusCode,
                        urlRequest: urlRequest,
                        data: data,
                        response: response
                    )
                }
            }
            
            step = .statusCodeValidation
            switch request.statusCodeValidation {
            case .default:
                guard let httpResponse = response as? HTTPURLResponse else { break }
                if !Range(200...299).contains(httpResponse.statusCode) {
                    throw APIError(
                        type: .invalidStatusCode,
                        statusCode: httpResponse.statusCode,
                        urlRequest: urlRequest,
                        data: data,
                        response: response
                    )
                }
            case .custom(let isValid):
                guard let httpResponse = response as? HTTPURLResponse else { break }
                if !isValid(httpResponse.statusCode) {
                    throw APIError(
                        type: .invalidStatusCode,
                        statusCode: httpResponse.statusCode,
                        urlRequest: urlRequest,
                        data: data,
                        response: response
                    )
                }
            case .none:
                break
            }
            
            step = .decoding
            let decoder = request.decoder ?? self.decoder
            do {
                let decoded: Request.Response = try await decoder.decode(data)
                step = .mapping
                let result: Mapped = try mapper(decoded)
                if let dispatchId {
                    stores.forEach { store in
                        Task { @MainActor in
                            store()?.requester(self, didGetResult: APIRequestingResult(request: request, failedStep: nil, error: nil), for: dispatchId)
                        }
                    }
                }
                return result
            } catch {
                throw APIError(
                    type: .decoding,
                    statusCode: (response as? HTTPURLResponse)?.statusCode,
                    underlyingError: error,
                    urlRequest: urlRequest,
                    data: data,
                    response: response
                )
            }
        } catch { // Log to NetworkStore if applicable
            guard let dispatchId else { throw error }
            let step = step
            stores.forEach { store in
                Task { @MainActor in
                    store()?.requester(self, didGetResult: APIRequestingResult(request: request, failedStep: step, error: error), for: dispatchId)
                }
            }
            throw error
        }
    }
}
