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
    var path: String { "delay/1000" }
    var backend: Requester.Backend { BackendMock.init(baseURL: URL(string: "https://flash-the-slow-api.herokuapp.com")!) }
}
