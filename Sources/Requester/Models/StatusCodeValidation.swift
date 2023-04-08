//
//  StatusCodeValidation.swift
//  
//
//  Created by Kevin van den Hoek on 30/01/2023.
//

import Foundation

public enum StatusCodeValidation {
    /// Will consider anything in 200-299 valid
    case `default`
    /// Statuscode from response won't matter
    case none
    /// Return true if statuscode is valid
    case custom((Int) -> Bool)
}
