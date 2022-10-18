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
    @discardableResult func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped
    @discardableResult func performWithMemoryCaching<Request: APIRequest, Mapped>(_ request: Request, maxCacheLifetime: TimeInterval?, mapper: (Request.Response) throws -> Mapped) async throws -> Mapped
}
