//
//  Global+Extension.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public func assertionFailing<T>(_ value: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) -> T {
    assertionFailure(message, file: file, line: line)
    return value
}
