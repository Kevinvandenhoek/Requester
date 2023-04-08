//
//  APIRequesting.swift
//  
//
//  Created by Kevin van den Hoek on 09/09/2022.
//

import Foundation

public protocol APIRequesting {
    
    var memoryCacher: MemoryCaching { get }
    
    @discardableResult func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response
    @discardableResult func performWithMemoryCaching<Request: APIRequest>(_ request: Request) async throws -> Request.Response
    @discardableResult func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped
    @discardableResult func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, maxCacheLifetime: CacheLifetime?, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped
    
    func setup(with store: NetworkActivityStore) async
}

protocol APIRequestingActivityDelegate: AnyObject {
    
    func requester(_ requester: APIRequesting, didGetResult result: APIRequestingResult, for id: APIRequestDispatchID)
}
