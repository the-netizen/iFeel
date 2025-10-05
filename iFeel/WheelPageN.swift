import SwiftUI

// MARK: - Helpers

extension Color {
    static let fuchsia = Color(red: 1.00, green: 0.18, blue: 0.61)
}

struct RingWedge: Shape {
    var startDeg: Double
    var endDeg: Double
    var innerRadiusFactor: CGFloat = 0.58
    var gapDegrees: Double = 5.0

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) * 0.5
        let rInner = rOuter * innerRadiusFactor
        let g = gapDegrees * .pi / 180 / 2
        let s = startDeg * .pi / 180 + g
        let e = endDeg   * .pi / 180 - g
        var p = Path()
        p.addArc(center: c, radius: rOuter, startAngle: .radians(s), endAngle: .radians(e), clockwise: false)
        p.addLine(to: CGPoint(x: c.x + rInner * CGFloat(cos(e)), y: c.y + rInner * CGFloat(sin(e))))
        p.addArc(center: c, radius: rInner, startAngle: .radians(e), endAngle: .radians(s), clockwise: true)
        p.closeSubpath()
        return p
    }
}

// MARK: - Wheel (Page 1)

struct WheelController: View {
    private let n = 7
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .fuchsia]
    private let titles  = ["ANGRY","BAD","HAPPY","DISGUSTED","SAD","FEARFUL","SURPRISED"]
    
    @State private var selected: Int? = nil
    @State private var wheelRotation: Double = 0
    @State private var isZooming: Bool = false
    @State private var goDetail: Bool = false
    @State private var showTechniquePage: Bool = false
    @State private var showCompletionPage: Bool = false

    var body: some View {
        NavigationStack {
            ZStack { wheel }
                .padding()
                .navigationDestination(isPresented: $goDetail) {
                    if let i = selected {
                        DetailScreen(
                            titleTop: "You Picked",
                            mood: titles[i],
                            color: colors[i],
                            onStart: { showTechniquePage = true }
                        )
                    }
                }
                .navigationDestination(isPresented: $showTechniquePage) {
                    // 1. Pass the selected color to the TechView
                    if let i = selected {
                        TechView(
                            onDone: { showCompletionPage = true },
                            backgroundColor: colors[i]
                        )
                    }
                }
                .navigationDestination(isPresented: $showCompletionPage) {
                    // 2. Pass the selected color to the CompletionView as well
                    if let i = selected {
                        CompletionView(
                            onDone: navigateBackToRoot,
                            themeColor: colors[i]
                        )
                    }
                }
        }
    }
    
    private func navigateBackToRoot() {
        showCompletionPage = false
        showTechniquePage = false
        goDetail = false
    }

    private var wheel: some View {
        let step = 360.0 / Double(n)
        return ZStack {
            ForEach(0..<n, id: \.self) { i in
                let start = Double(i) * step
                let end   = Double(i + 1) * step
                let mid   = (start + end) / 2.0
                let rad   = mid * .pi / 180

                let isSel = (selected == i)
                let dx = isSel ? 18 * CGFloat(cos(rad)) : 0
                let dy = isSel ? 18 * CGFloat(sin(rad)) : 0

                RingWedge(startDeg: start, endDeg: end, innerRadiusFactor: 0.58, gapDegrees: 5.0)
                    .fill(colors[i])
                    .compositingGroup()
                    .shadow(color: .black.opacity(0.30), radius: 8, y: 4)
                    .overlay(
                        RingWedge(startDeg: start, endDeg: end, innerRadiusFactor: 0.58, gapDegrees: 5.0)
                            .stroke(.white.opacity(0.9), lineWidth: 1)
                    )
                    .offset(x: dx, y: dy)
                    .scaleEffect(isSel && isZooming ? 2.0 : 1.0)
                    .zIndex(isSel && isZooming ? 1 : 0)
                    .onTapGesture { handleTap(index: i, mid: mid) }
            }
        }
        .frame(width: 280, height: 280)
        .rotationEffect(.degrees(wheelRotation))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: wheelRotation)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: isZooming)
    }

    private func handleTap(index i: Int, mid: Double) {
        let already = (selected == i)
        selected = already ? nil : i
        guard !already else { return }
        let currentWorldAngle = mid + wheelRotation
        let delta = -90.0 - currentWorldAngle
        let normalizedDelta = ((delta + 180).truncatingRemainder(dividingBy: 360)) - 180
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { wheelRotation += normalizedDelta }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + 0.55) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { isZooming = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + 0.55 + 0.45) {
            goDetail = true
            isZooming = false
        }
    }
}

struct DetailScreen: View {
    let titleTop: String
    let mood: String
    let color: Color
    var onStart: () -> Void = {}

    var titleTopPadding: CGFloat = 330
    var heroTop: CGFloat = 570
    var heroDiameter: CGFloat = 750
    var sliceSpanDeg: Double = 85
    var sliceInnerFactor: CGFloat = 0.20
    var neighborsSpanScale: Double = 0.88
    var neighborsGapDeg: Double = 1.5
    var neighborsOffsetDeg: Double = -6
    var glowOpacity: Double = 0.35
    var glowBlur: CGFloat = 55
    var bottomCircleScale: CGFloat = 1.2
    var bottomYOffsetFactor: CGFloat = 0.93
    var startButtonOffset: CGFloat = 280

    
    @State var shouldNav : Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ZStack(alignment: .top) {
                hero
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, heroTop)
                VStack(spacing: 8) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .tint(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)

                    VStack(spacing: 6) {
                        Text(titleTop)
                        .font(Font.custom("Comfortaa-Bold", size: 28)) // Apply Comfortaa font
                        .fontWeight(.heavy)
                        Text(mood.uppercased()).font(.system(size: 60, weight: .heavy))
                    }
                }
                .padding(.top, titleTopPadding)
            }
            bottomOverlay
        }
        .navigationBarBackButtonHidden(true)
    }

    private var hero: some View {
        ZStack {
            let span = sliceSpanDeg
            let start = -90.0 - span/2
            let end   = -90.0 + span/2
            let nSpan = span * neighborsSpanScale
            Circle()
                .fill(color.opacity(glowOpacity))
                .frame(width: heroDiameter * 0.9, height: heroDiameter * 0.9)
                .blur(radius: glowBlur)
                .blendMode(.plusLighter)
                .offset(y: 8)
            RingWedge(startDeg: start - neighborsOffsetDeg - nSpan,
                      endDeg:   start - neighborsOffsetDeg,
                      innerRadiusFactor: sliceInnerFactor,
                      gapDegrees: neighborsGapDeg)
                .fill(Color.black.opacity(0.16))
                .frame(width: heroDiameter, height: heroDiameter)
            RingWedge(startDeg: end + neighborsOffsetDeg,
                      endDeg:   end + neighborsOffsetDeg + nSpan,
                      innerRadiusFactor: sliceInnerFactor,
                      gapDegrees: neighborsGapDeg)
                .fill(Color.black.opacity(0.16))
                .frame(width: heroDiameter, height: heroDiameter)
            RingWedge(startDeg: start, endDeg: end,
                      innerRadiusFactor: sliceInnerFactor, gapDegrees: 20)
                .fill(color)
                .frame(width: heroDiameter, height: heroDiameter)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .frame(height: heroDiameter)
    }

    private var bottomOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: UIScreen.main.bounds.width * bottomCircleScale,
                       height: UIScreen.main.bounds.width * bottomCircleScale)
                .offset(y: UIScreen.main.bounds.width * bottomYOffsetFactor)
                .shadow(color: .black.opacity(0.08), radius: 16, y: -4)

            
            Button {
                shouldNav.toggle()
            } label: {
                Text("START")
                    .font(Font.custom("comfortaa-bold", size: 22))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }.offset(y: startButtonOffset)
            

//            Button(action: onStart) {
//                Text("START")
//                    .font(.system(size: 22, weight: .semibold))
//                    .padding(.horizontal, 36)
//                    .padding(.vertical, 14)
//                    .background(color)
//                    .foregroundStyle(.white)
//                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          //  }.
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationDestination(isPresented: $shouldNav) {
            MindOnboardingView()
        }
    }
}


// MARK: - Technique (Page 3)

struct TechView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0
    var onDone: () -> Void = {}
    
    // 1. Add a property to accept the background color
    var backgroundColor: Color = Color(red: 0.90, green: 1.0, blue: 0.90)

    private let pages = [
        "Focus on your body and thoughts", "Take deep breaths and relax",
        "Clear your mind and meditate", "Journal your thoughts and feelings"
    ]

    var body: some View {
        ZStack {
            // 2. Use the passed-in color for the background
            backgroundColor.opacity(0.25).ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    if currentPage == pages.count - 1 {
                        Button {
                            hasSeenOnboarding = true
                            onDone()
                        } label: {
                            Text("Done").fontWeight(.medium).foregroundColor(.primary) // Use .primary for better contrast
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 20).frame(height: 50)
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack {
                            Spacer()
                            Image(systemName: "leaf.fill").resizable().scaledToFit()
                                .frame(maxHeight: 200).foregroundColor(.secondary).padding(.bottom, 50)
                            Text(pages[i]).font(.system(size: 22, weight: .medium))
                                .multilineTextAlignment(.center).foregroundColor(.primary)
                                .padding(.horizontal, 70)
                            Spacer()
                        }.tag(i)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle().fill(i == currentPage ? Color.primary : Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .onTapGesture { withAnimation { currentPage = i } }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}


// MARK: - Confetti Views

struct ConfettiPiece: View {
    @State private var yPos: CGFloat = .random(in: -200...0)
    @State private var xPos: CGFloat = .random(in: -20...20)
    @State private var rotation = Angle.degrees(.random(in: 0...360))
    @State private var opacity: Double = 0.0

    let color: Color = [.blue, .red, .green, .yellow, .purple, .orange].randomElement()!
    let duration = Double.random(in: 2.5...4.0)

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 10, height: 10)
            .rotationEffect(rotation, anchor: .center)
            .offset(x: xPos, y: yPos)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 0.2)) { opacity = 1.0 }
                withAnimation(.linear(duration: duration).delay(0.1)) {
                    yPos = 800
                    xPos += .random(in: -150...150)
                    rotation += Angle(degrees: .random(in: 360...1080))
                }
                withAnimation(.linear(duration: 1.0).delay(duration - 1.0)) { opacity = 0 }
            }
    }
}

struct ConfettiView: View {
    var body: some View {
        ZStack {
            ForEach(0..<150) { _ in ConfettiPiece() }
        }
    }
}

// MARK: - Completion View (Page 4)

struct CompletionView: View {
    var onDone: () -> Void = {}
    
    
    var themeColor: Color = .black

    var body: some View {
        ZStack {
            
            Color.white.ignoresSafeArea()
            
            ConfettiView()

            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, themeColor)
                
                Text("Well Done!")
                    .font(.custom("Comfortaa-Bold", size: 34))  // Make sure the font name is correct
                    .fontWeight(.bold)
                
                Text("You have successfully completed the technique.")
    
                    .font(.custom("Comfortaa-Bold", size: 20))  // Make sure the font name is correct
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onDone) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(. black)  // Change color to black
                    
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    WheelController()
}
