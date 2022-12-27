//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 23/12/2022.
//

import Foundation

public protocol URLSessionProviding {
    func urlSession<Request: APIRequest>(for request: Request) -> URLSession
}
