//
//  CachingGroup.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public protocol CachingGroup: Sendable {
    
    var id: String { get }
}
