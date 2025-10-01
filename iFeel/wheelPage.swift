//
//  wheelPage.swift
//  iFeel
//
//  Created by Naima Khan on 29/09/2025.
//

import SwiftUI

struct SegmentIcon: Shape {
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

struct DonutView: View {
    private let n = 7
    private let colors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
    private let explodeDistance: CGFloat = 18       // كم تبعد القطعة عند الضغط
    private let holeDiameter: CGFloat = 100         // قطر ثقب الدونات

    @State private var selected: Int? = nil         // رقم القطعة المختارة

    var body: some View {
        let step = 360.0 / Double(n)

        ZStack {
            ForEach(0..<n, id: \.self) { i in
                let start = Angle(degrees: step * Double(i))
                let end   = Angle(degrees: step * Double(i + 1))
                let midDeg = (start.degrees + end.degrees) / 2.0
                let rad = (midDeg) * .pi / 180

                let isSelected = (selected == i)
                let dx = isSelected ? explodeDistance * CGFloat(cos(rad)) : 0
                let dy = isSelected ? explodeDistance * CGFloat(sin(rad)) : 0

                SegmentIcon(startAngle: start, endAngle: end)
                    .fill(colors[i % colors.count])
                    .overlay(
                        SegmentIcon(startAngle: start, endAngle: end)
                            .stroke(.white.opacity(0.9), lineWidth: 6)
                    )
                    .offset(x: dx, y: dy)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selected = isSelected ? nil : i
                        }
                    }
                    
            }

            // ثقب الدونات (لا يستقبل لمس)
            Circle()
                .fill(Color(.systemBackground))
//                .frame(width: holeDiameter, height: holeDiameter)
                .frame(width: 130, height: 130)
                .allowsHitTesting(false)
                
        }
//        .frame(width: 320, height: 320)
        .frame(width: 350, height: 350)
        
    }
}

#Preview {
    DonutView()
}
