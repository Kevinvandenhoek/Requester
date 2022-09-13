//
//  APIRequesting.swift
//  
//
//  Created by Kevin van den Hoek on 09/09/2022.
//

import Foundation

public protocol APIRequesting {
    
    @discardableResult func perform<Request: APIRequest>(_ request: Request) async throws -> Request.Response
}
