//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 09/06/2023.
//

import Foundation

public extension NetworkActivityOverlay {
    
    /// Initializes a NetworkActivityView with NetworkActicityStore.default. Be sure to use the setup method on this store to set it up with your request dispatcher
    init(_ store: NetworkActivityStore = .default) {
        self.init(store: store)
    }
}
