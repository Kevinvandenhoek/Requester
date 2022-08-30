//
//  URL+Extension.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public extension URL {
 
    func adding(queryItems: [URLQueryItem]) -> URL {
        guard !queryItems.isEmpty, var urlComponents = URLComponents(string: absoluteString) else { return self }
        urlComponents.queryItems = (urlComponents.queryItems ?? []) + queryItems
        return urlComponents.url ?? assertionFailing(self, "Failed to add queryitems to url")
    }
}
