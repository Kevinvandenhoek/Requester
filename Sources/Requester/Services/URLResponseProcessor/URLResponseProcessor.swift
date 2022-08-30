//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol URLResponseProcessor {
    
    func process<Request: APIRequest>(_ response: URLResponse, data: Data, request: Request) throws
}
