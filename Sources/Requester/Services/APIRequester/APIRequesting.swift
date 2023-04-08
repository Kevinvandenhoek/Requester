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

public extension APIRequesting {
    
    /// Will enable viewing network activity with NetworkActivityView. Shortcut to call setup(with: NetworkActivityStore.default).
    func setupActivityMonitoring() async {
        await setup(with: .default)
    }
}
