//
//  File.swift
//  
//
//  Created by Kevin van den Hoek on 08/04/2023.
//

import Foundation
import SwiftUI

struct DottedSeparator: View {
    var color: Color = Color(.systemGray4)
    var height: CGFloat
    var dotRadius: CGFloat
    var spacing: CGFloat
    
    init(height: CGFloat = 3) {
        self.height = height
        self.dotRadius = height / 2
        self.spacing = height * 2
    }

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let totalWidth = geometry.size.width
                var currentX: CGFloat = 0
                
                while currentX < totalWidth {
                    path.addEllipse(in: CGRect(x: currentX, y: 0, width: dotRadius * 2, height: height))
                    currentX += dotRadius * 2 + spacing
                }
            }
            .fill(color)
        }
        .frame(height: height)
    }
}
