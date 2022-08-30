//
//  APIAuthenticationToken.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol APIAuthenticationToken {
    
    /// This is used to (silently) cancel existing requests with the same authenticator whenever the backend rejects the token. All cancelled requests will automatically be retried after a single token refresh.
    var id: UUID { get }
    var expiryDate: Date { get }
}
