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
    var path: String { "1000/www.google.com" }
    var backend: Requester.Backend { .stubbed(baseURL: URL(string: "https://deelay.me/")!) }
}
