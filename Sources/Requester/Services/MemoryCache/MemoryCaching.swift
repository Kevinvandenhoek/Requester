//
//  MemoryCaching.swift
//  
//
//  Created by Kevin van den Hoek on 09/09/2022.
//

import Foundation

public protocol MemoryCaching: Sendable {
    
    func store<Request: APIRequest, Model>(request: Request, model: Model) async
    func get<Request: APIRequest, Model>(request: Request) async -> Model?
    func get<Request: APIRequest, Model>(request: Request, maxLifetime: CacheLifetime?) async -> Model?
    func clear() async
    func clear(_ group: CachingGroup) async
    func clear(_ groups: [CachingGroup]) async
}
