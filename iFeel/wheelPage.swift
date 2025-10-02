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
//        center and radius calculated based on screen size (CGRect)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path() //create custom path variable
        
        path.move(to: center) //create arc
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath() //connects arc to center to make a slice shape
        return path
    }
}

struct DonutView: View {
    private let numOfSegments = 7
    private let feelings = [
        "Fearful",
         "Sad",
         "Disgusted",
         "Happy",
         "Bad",
         "Angry",
         "Surprised"
    ]
    let colors: [Color] = [
        Color(hex: 0xCE96FD), // fearful
        Color(hex: 0x8582CA), // sad
        Color(hex: 0x8FC688), // disgusted
        Color(hex: 0xFFF654), // happy
        Color(hex: 0xFFAA76), // bad
        Color(hex: 0xED6B6B), // angry
        Color(hex: 0xF689D8)  // surprised
    ]
    
    
    private let explodeDistance: CGFloat = 20 //how much a seg will move when selected
    private let holeSize: CGFloat = 130  //diameter of inner circle
    private let labelOffset: CGFloat = 120 // distance from center

    @State private var selected: Int? = nil  //selected segment index

    var body: some View {
        VStack (spacing: 30){
            
//---            Title -1
            Text("How are you ")
                .font(.system(size: 40, design: .rounded))
                .foregroundColor(.primary)
                .padding(.bottom)
            
            // angle of each segment
            let step = 360.0 / Double(numOfSegments)
            
            ZStack {
                ForEach(0..<numOfSegments, id: \.self) { i in
                    let startAngle = Angle(degrees: step * Double(i)) // start angle of current segment
                    let endAngle   = Angle(degrees: step * Double(i + 1)) // end angle of current segment
                    let midAngle = (startAngle.degrees + endAngle.degrees) / 2.0
                    let rad = (midAngle) * .pi / 180 //used to calculate offset angle
                    
                    let isSelected = (selected == i)
                    let dx = isSelected ? explodeDistance * CGFloat(cos(rad)) : 0  // x-axis
                    let dy = isSelected ? explodeDistance * CGFloat(sin(rad)) : 0 // y-axis
//                    let textRotation = Angle(degrees: (midAngle > 90 && midAngle < 270) ? midAngle + 180 : midAngle)

                    
//---                Draw donut segment
                    SegmentIcon(startAngle: startAngle, endAngle: endAngle)
                        .fill(colors[i % colors.count])
                        .overlay(
                            SegmentIcon(startAngle: startAngle, endAngle: endAngle)
                                .stroke(.white.opacity(0.9))
                        )
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .offset(x: dx, y: dy) //if segment selected, animate with dx, dy offset
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selected = isSelected ? nil : i
                            }
                        }
                    
//---                Segment labels
                    Text(feelings[i])
                        .foregroundColor(.black)
                        .offset(x: labelOffset * CGFloat(cos(rad)),
                                y: labelOffset * CGFloat(sin(rad)))  //distance btw labels

                    
                        .offset(x: dx, y: dy) // same explosion offset as segment
                    
                    
                } //for-each ends
                
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 180, height: 180)
//                    .shadow(radius: 0, x: 0, y: 10)
                    .allowsHitTesting(false)
                
//---                Center Text
                    if let index = selected {
                        VStack {
                            Text(feelings[index])
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.heavy)
                                .foregroundColor(colors[index])
                        }
                    } else {
                        Text("Tap")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            
                    }
                
            } //zstack end
            .frame(width: 350, height: 350)
            
            Text("Feeling?")
                .font(.system(size: 40, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top)
        } // vstack ends
//        .shadow(radius: 0, x: 0, y: 10)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}


#Preview {
    DonutView()
}
