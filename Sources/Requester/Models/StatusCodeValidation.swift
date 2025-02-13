//
//  StatusCodeValidation.swift
//  
//
//  Created by Kevin van den Hoek on 30/01/2023.
//

import Foundation

public enum StatusCodeValidation: Sendable {
    /// Will consider anything in 200-299 valid
    case `default`
    /// Statuscode from response won't matter
    case none
    /// Return true if statuscode is valid
    case custom(StatusCodeValidator)
}

public protocol StatusCodeValidator: Sendable {
    
    func isValid(_ code: Int) -> Bool
}
