//
//  TestAPIRequest.swift
//  
//
//  Created by Kevin van den Hoek on 13/09/2022.
//

import Foundation
import Requester

struct TestAPIRequest: APIRequest {
    
    typealias Response = String
    
    var method: Requester.APIMethod { .get }
    var path: String { "get" }
    var backend: Requester.Backend { .stubbed(baseURL: URL(string: "https://httpbin.org")!) }
}
