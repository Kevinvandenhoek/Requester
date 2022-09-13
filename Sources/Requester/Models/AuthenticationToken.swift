//
//  AuthenticationToken.swift
//  
//
//  Created by Kevin van den Hoek on 30/08/2022.
//

import Foundation

public typealias TokenID = String

public protocol AuthenticationToken {
    var id: TokenID { get }
}
