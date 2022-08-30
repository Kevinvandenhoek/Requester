//
//  URLRequestMapper.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public struct URLRequestMapper {
    
    public let jsonEncoder: JSONEncoder
    
    public init(jsonEncoder: JSONEncoder = JSONEncoder()) {
        self.jsonEncoder = jsonEncoder
    }
    
    public func map<Request: APIRequest>(_ apiRequest: Request) throws -> URLRequest {
        let url = apiRequest.backend.baseURL.appendingPathComponent(apiRequest.path)
        var urlRequest = URLRequest(url: url)
        
        setMethod(on: &urlRequest, for: apiRequest)
        setHeaders(on: &urlRequest, for: apiRequest)
        try setParameters(on: &urlRequest, for: apiRequest)
        
        return urlRequest
    }
}

private extension URLRequestMapper {
    
    func setMethod<Request: APIRequest>(on urlRequest: inout URLRequest, for apiRequest: Request) {
        urlRequest.httpMethod = apiRequest.method.rawValue
    }
    
    func setHeaders<Request: APIRequest>(on urlRequest: inout URLRequest, for apiRequest: Request) {
        apiRequest.headers.forEach({ header in
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        })
    }
    
    func setParameters<Request: APIRequest>(on urlRequest: inout URLRequest, for apiRequest: Request) throws {
        switch apiRequest.parameterEncoding {
        case .url(let destination):
            switch destination ?? URLEncodingDestination.default(for: apiRequest.method) {
            case .body:
                urlRequest.httpBody = apiRequest.parameters.percentEncoded
            case .queryString:
                guard let url = urlRequest.url else { return }
                urlRequest.url = url.adding(queryItems: apiRequest.parameters.map({ (key, value) in
                    return URLQueryItem(name: key, value: String(describing: value))
                }))
            }
        case .json:
            urlRequest.httpBody = try JSONSerialization
                .data(withJSONObject: apiRequest.parameters as Any)
        case .urlAndJson(let urlKeys):
            guard let url = urlRequest.url else { return }
            let urlParameters = apiRequest.parameters.filter({ urlKeys.contains($0.key) })
            let jsonParameters = apiRequest.parameters.filter({ !urlKeys.contains($0.key) })
            
            urlRequest.url = url.adding(queryItems: urlParameters.map({ parameter in
                return URLQueryItem(name: parameter.key, value: parameter.value as? String)
            }))
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: jsonParameters as Any)
        case .jsonArray:
            guard let parameters = apiRequest.parameters[ParameterEncoding.jsonArrayKey] else { return }
            urlRequest.httpBody = try JSONSerialization
                .data(withJSONObject: parameters as Any)
        case .custom(let encoder):
            encoder(apiRequest.parameters, &urlRequest)
        }
    }
}
