//
//  wheelPage.swift
//  iFeel
//
//  Created by Naima Khan on 29/09/2025.
//

import SwiftUI

struct MyIcon: Shape {
    var startAngle: Angle
    var endAngle: Angle

        func path(in rect: CGRect) -> Path {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            
            var path = Path()
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
            path.closeSubpath()
            return path
        }
}

struct DonutView : View {
    let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
    let segmentAngle = 360.0 / 7.0

        var body: some View {
            ZStack {
                ForEach(0..<7) { index in
                    MyIcon(
                        startAngle: .degrees(segmentAngle * Double(index)),
                        endAngle: .degrees(segmentAngle * Double(index + 1))
                    )
                    .fill(colors[index])
                }
                
                // This is the hole in the donut
                Circle()
                    .fill(Color(.systemBackground)) // Or your desired background color
                    .frame(width: 100, height: 100) // Adjust the hole size here
            }
            
            .frame(width: 250, height: 250)
        }
}

#Preview {
    DonutView()
    
}

