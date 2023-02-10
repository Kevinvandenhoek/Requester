//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 10/02/2023.
//

import Foundation

public typealias CacheLifetime = TimeInterval

public extension CacheLifetime {
    
    /// A few seconds, typically used when you know the same call is going to be called a multitude of times within a few seconds, but you want to use pretty much fresh data
    static var ephemeral: TimeInterval {
        return 10
    }
    
    /// A few minutes, typically used when you know the same call is going to be called a multitude of times within a few seconds, but you want to use pretty much fresh data
    static var minutary: TimeInterval {
        return 5 * 60
    }
    
    /// An hour
    static var hourly: TimeInterval {
        return 1 * 60 * 60
    }
    
    /// 24 hours
    static var daily: TimeInterval {
        return 24 * 60 * 60
    }
}
