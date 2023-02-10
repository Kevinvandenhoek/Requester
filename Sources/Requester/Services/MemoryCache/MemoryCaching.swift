//
//  MemoryCaching.swift
//  
//
//  Created by Kevin van den Hoek on 09/09/2022.
//

import Foundation

public protocol MemoryCaching {
    
    func store<Request: APIRequest, Model>(request: Request, model: Model) async
    func get<Request: APIRequest, Model>(request: Request) async -> Model?
    func get<Request: APIRequest, Model>(request: Request, maxLifetime: CacheLifetime?) async -> Model?
    func clear() async
    func clear(groups: CachingGroup...) async
    func clear(groups: Set<CachingGroup>) async
}
