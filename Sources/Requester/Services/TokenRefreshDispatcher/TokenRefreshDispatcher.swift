//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation
import Combine

public protocol TokenRefreshDispatching {
    func performTokenRefresh(with authenticator: Authenticating, tokenID: TokenID?) async throws
}

public actor TokenRefreshDispatcher: TokenRefreshDispatching {
    
    private let piggyBacker: PiggyBacker<TokenID, Future<Void, Error>>
    
    public init(piggyBacker: PiggyBacker<TokenID, Future<Void, Error>> = .init()) {
        self.piggyBacker = piggyBacker
    }
    
    public func performTokenRefresh(with authenticator: Authenticating, tokenID: TokenID?) async throws {
        guard let tokenID = tokenID else { return try await authenticator.fetchToken() }
        return try await piggyBacker.dispatch(tokenID) { tokenID in
            return Future<Void, Error>() { promise in
                Task {
                    do {
                        try await authenticator.fetchToken()
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
