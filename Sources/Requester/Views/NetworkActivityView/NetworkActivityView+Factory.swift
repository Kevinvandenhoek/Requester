//
//  NetworkActivityView+Factory.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation

extension NetworkActivityView {
    
    /// Initializes a NetworkActivityView with NetworkActicityStore.default. Be sure to use the setup method on this store to set it up with your request dispatcher
    init() {
        self.init(store: .default)
    }
}
