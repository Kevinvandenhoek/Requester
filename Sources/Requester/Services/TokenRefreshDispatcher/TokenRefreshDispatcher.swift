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
    
    private let piggyBacker: PiggyBacker<TokenID, Future<Void, Error>, Int>
    
    public init(piggyBacker: PiggyBacker<TokenID, Future<Void, Error>, Int> = .init()) {
        self.piggyBacker = piggyBacker
    }
    
    public func performTokenRefresh(with authenticator: Authenticating, tokenID: TokenID?) async throws {
        let dispatchID = tokenID ?? String(describing: type(of: authenticator))
        return try await piggyBacker.dispatch(dispatchID) { _ in
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
