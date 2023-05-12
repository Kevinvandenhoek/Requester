//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 12/05/2023.
//

import Foundation

extension Array {
    
    func asyncFilter(_ predicate: @escaping (Element) async -> Bool) async -> [Element] {
        var filteredElements: [Element] = []
        await withTaskGroup(of: (element: Element, shouldInclude: Bool).self) { group in
            for element in self {
                group.addTask {
                    let shouldInclude = await predicate(element)
                    return (element: element, shouldInclude: shouldInclude)
                }
            }

            for await result in group {
                if result.shouldInclude {
                    filteredElements.append(result.element)
                }
            }
        }
        return filteredElements
    }
}
