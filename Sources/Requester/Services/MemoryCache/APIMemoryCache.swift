//
//  APIMemoryCache.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIMemoryCache {
    
    func store<Request: APIRequest, Model>(request: Request, model: Model) async
    func get<Request: APIRequest, Model>(request: Request) async -> Model?
    func get<Request: APIRequest, Model>(request: Request, maxLifetime: TimeInterval) async -> Model?
    func clear() async
    func clear(groups: APICachingGroup...) async
    func clear(groups: [APICachingGroup]) async
}

actor APIMemoryCacheService: APIMemoryCache {
    
    typealias RequestHash = Int
    
    private var storage: [RequestKey: StoredModel] = [:]
    
    func store<Request: APIRequest, Model>(request: Request, model: Model) async {
        let key = RequestKey(for: request)
        storage[key] = StoredModel(model)
    }
    
    func get<Request: APIRequest, Model>(request: Request) async -> Model? {
        return await get(request: request, maxLifetime: .greatestFiniteMagnitude)
    }
    
    func get<Request: APIRequest, Model>(request: Request, maxLifetime: TimeInterval) async -> Model? {
        let date = Date()
        let key = RequestKey(for: request)
        guard let stored = storage[key],
              date.timeIntervalSince(stored.date) < maxLifetime,
              let model = stored.model as? Model else {
            storage[key] = nil
            return nil
        }
        return model
    }
    
    func clear() async {
        storage = [:]
    }
    
    func clear(groups: APICachingGroup...) async {
        await clear(groups: groups)
    }
    
    func clear(groups: [APICachingGroup]) async {
        storage.keys.forEach({ request in
            guard request.cachingGroups.contains(where: { group in
                return groups.map({ $0.id }).contains(group.id)
            }) else { return }
            storage.removeValue(forKey: request)
        })
    }
}

private extension APIMemoryCacheService {
    
    struct StoredModel {
        let model: Any
        let date: Date
        
        init(_ model: Any) {
            self.model = model
            self.date = Date()
        }
    }
    
    struct RequestKey: Hashable {
        let hashable: HashableRequest
        let cachingGroups: [APICachingGroup]
        
        init<Request: APIRequest>(for request: Request) {
            hashable = HashableRequest(from: request)
            cachingGroups = request.cachingGroups
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.hashable == rhs.hashable
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(hashable)
        }
    }
}

private struct HashableRequest: Hashable {
    
    let parameters: NSDictionary
    let headers: [String: String]
    let backend: APIBackend
    let path: String
    
    init<Request: APIRequest>(from request: Request) {
        self.parameters = request.parameters as NSDictionary
        self.headers = request.headers
        self.backend = request.backend
        self.path = request.path
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.headers == rhs.headers
            && lhs.backend.baseURL == rhs.backend.baseURL // TODO: Check if we can take all members in consideration instead of just the baseURL
            && lhs.path == rhs.path
            && lhs.parameters == rhs.parameters
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(headers)
        hasher.combine(backend.baseURL)
        hasher.combine(path)
        hasher.combine(parameters)
    }
}
