//
//  URLSessionDelegateWrapper.swift
//  
//
//  Created by Kevin van den Hoek on 29/12/2022.
//

import Foundation

public final class URLSessionDelegateWrapper: NSObject, URLSessionDelegate {
    
    var onDidReceiveChallenge: ((URLSession, URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?))?
     
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if let onDidReceiveChallenge = onDidReceiveChallenge {
            return await onDidReceiveChallenge(session, challenge)
        } else {
            return (.performDefaultHandling, nil)
        }
    }
}
