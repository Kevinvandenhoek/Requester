//
//  URLSessionConfigurationProviding.swift
//  
//
//  Created by Kevin van den Hoek on 23/12/2022.
//

import Foundation

public protocol URLSessionConfigurationProviding {
    func make<Request: APIRequest>(for request: Request) -> URLSessionConfiguration
}
