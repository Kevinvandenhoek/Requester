//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 18/10/2022.
//

import Foundation
@testable import Requester

@MainActor final class MemoryCacherMock: MemoryCaching {
    
    var invokedStore = false
    var invokedStoreCount = 0
    func store<Request: APIRequest, Model>(request: Request, model: Model) async {
        invokedStore = true
        invokedStoreCount += 1
    }
    
    var invokedGet = false
    var invokedGetCount = 0
    var stubbedGetResult: Any? = nil
    func get<Request: APIRequest, Model>(request: Request) async -> Model? {
        invokedGet = true
        invokedGetCount += 1
        return stubbedGetResult as? Model
    }
    
    var invokedGetMaxLifetime = false
    var invokedGetMaxLifetimeCount = 0
    func get<Request: APIRequest, Model>(request: Request, maxLifetime: TimeInterval?) async -> Model? {
        invokedGetMaxLifetime = true
        invokedGetMaxLifetimeCount += 1
        return stubbedGetResult as? Model
    }
    
    var invokedClear = false
    var invokedClearCount = 0
    func clear() async {
        invokedClear = true
        invokedClearCount += 1
    }
    
    var invokedGroups = false
    var invokedGroupsCount = 0
    func clear(_ groups: [CachingGroup]) async {
        invokedGroups = true
        invokedGroupsCount += 1
    }
    
    func clear(_ group: CachingGroup) async {
        await clear([group])
    }
}
