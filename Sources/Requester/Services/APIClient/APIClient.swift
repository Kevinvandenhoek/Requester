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
            var urlRequest = try urlRequestMapper.map(request)
            
            if let requestProcessor = request.backend.requestProcessor {
                try requestProcessor.process(&urlRequest)
            }
            
            if let authenticator = request.backend.authenticator {
                switch authenticator.authenticate(request: &urlRequest) {
                case .failure(let error):
                    try await authenticator.refreshToken()
                case .success:
                    break
                }
            }
            
            let (data, response) = try await dispatchQueue.dispatch(urlRequest, request)
            
            if let responseProcessor = request.backend.responseProcessor {
                try responseProcessor.process(response, data: data, request: request)
            }
            let decoder = request.decoder ?? self.decoder
            return try decoder.decode(data)
//        } catch let error as APIError {
//            switch error.type {
//            case .missingToken, .unauthorized:
//                guard allowTokenRefresh,
//                      let tokenRefresher = getTokenRefresher(for: request) else {
//                    let error = error.toCMDataError()
//                    handleAnalyticsFor(error, request: request)
//                    throw error
//                }
//                try await tokenRefresher.refreshToken()
//                return try await perform(request, allowTokenRefresh: false)
//            default:
//                let error = error.toCMDataError()
//                handleAnalyticsFor(error, request: request)
//                throw error
//            }
            // TODO: Implement refresh mechanic
        } catch {
            throw error
        }
    }
}
