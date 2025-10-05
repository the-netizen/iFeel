import SwiftUI

// MARK: - 1. Helpers

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

struct MoodTechnique {
    let text: String
    let icon: String
}

// MARK: - 2. DetailScreen (Page 2) - Must be defined BEFORE WheelController

struct DetailScreen: View {
    let titleTop: String
    let mood: String
    let color: Color
    var onStart: () -> Void = {}

    // Layout parameters
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
                            .font(Font.custom("Comfortaa-Bold", size: 28))
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

            Button(action: onStart) {
                Text("START")
                    .font(Font.custom("Comfortaa-Bold", size: 22))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .offset(y: startButtonOffset)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - 3. WheelController (Page 1)

struct WheelController: View {
    private let n = 7
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .fuchsia]
    private let titles  = ["ANGRY","BAD","HAPPY","DISGUSTED","SAD","FEARFUL","SURPRISED"]
    private let feelings = [
        "Fearful", "Sad", "Disgusted", "Happy", "Bad", "Angry", "Surprised"
    ]
    
    @State private var selected: Int? = nil
    @State private var wheelRotation: Double = 0
    @State private var isZooming: Bool = false
    @State private var goDetail: Bool = false
    @State private var showTechniquePage: Bool = false
    @State private var showCompletionPage: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("How are you")
                    .font(.system(size: 40, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.bottom, 40)
                    
                ZStack { wheel }
                    .padding()
                    
                Text("Feeling")
                    .font(.system(size: 40, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 40)
            } //VStack
            
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
            // Passes all required data to the new TechView
            .navigationDestination(isPresented: $showTechniquePage) {
                if let i = selected {
                    let mood = titles[i]
                    // Call the function that returns a random technique
                    let data = getTechniqueData(for: mood)
                    
                    TechView(
                        moodTitle: mood,
                        techniqueText: data.text,
                        techniqueIcon: data.icon,
                        backgroundColor: colors[i],
                        onDone: { showCompletionPage = true }
                    )
                }
            }
            .navigationDestination(isPresented: $showCompletionPage) {
                if let i = selected {
                    CompletionView(
                        onDone: navigateBackToRoot,
                        themeColor: colors[i]
                    )
                }
            }
            
        }// navStack
    }
    
    private func navigateBackToRoot() {
        showCompletionPage = false
        showTechniquePage = false
        goDetail = false
    }

    // FUNCTION: Returns a randomly selected technique for the given mood
    private func getTechniqueData(for mood: String) -> MoodTechnique {
        let techniques: [MoodTechnique]
        
        switch mood.uppercased() {
        case "ANGRY":
            techniques = [
                // Set the icon string to the custom asset name "breathe"
                // The string "breathe" matches your asset name.
                MoodTechnique(text: "Take 10 deep, slow breaths. Focus only on the air moving in and out.", icon: "breathe"),
                MoodTechnique(text: "Practice a 5-minute grounding exercise: Name 5 things you see, 4 you feel, 3 you hear, 2 you smell, and 1 you taste.", icon: "bolt.fill"),
                MoodTechnique(text: "Do 20 jumping jacks or a quick burst of vigorous physical activity to release tension.", icon: "figure.walk"),
                MoodTechnique(text: "Write down exactly what made you angry, then tear up the paper.", icon: "pencil.and.paper")
            ]
        case "SAD":
            techniques = [
                MoodTechnique(text: "Clear your mind and meditate for 10 minutes, focusing on self-compassion.", icon: "figure.mind.and.body"),
                MoodTechnique(text: "Listen to music that matches your mood, then switch to something calming or uplifting.", icon: "music.note"),
                MoodTechnique(text: "Journal your thoughts and feelings without judgment to understand the source of your sadness.", icon: "book.fill"),
                MoodTechnique(text: "Reach out to a friend or loved one for a brief, positive conversation.", icon: "person.2.fill")
            ]
        case "HAPPY":
            techniques = [
                MoodTechnique(text: "Journal your gratitudes: list 5 things you're truly thankful for right now.", icon: "face.smiling.fill"),
                MoodTechnique(text: "Share your positive mood with someone else a compliment or a shared smile.", icon: "heart.fill"),
                MoodTechnique(text: "Take a picture of something that represents this positive moment to remember it later.", icon: "camera.fill")
            ]
        case "FEARFUL":
            techniques = [
                MoodTechnique(text: "Focus on your body and thoughts to stay present. Name your fear, then question its reality.", icon: "eye.fill"),
                MoodTechnique(text: "Create a safe space: find a quiet spot and wrap yourself in a cozy blanket.", icon: "house.fill"),
                MoodTechnique(text: "Repeat a calming mantra to yourself, like 'I am safe' or 'This feeling will pass'.", icon: "infinity")
            ]
        case "SURPRISED":
            techniques = [
                MoodTechnique(text: "Take a moment to process the sudden change. Don't react instantly.", icon: "sparkles"),
                MoodTechnique(text: "Ask yourself if the surprise is positive or negative, and how you need to respond to it.", icon: "questionmark.circle.fill"),
                MoodTechnique(text: "Write down the event and analyze the shock. Break it down into facts.", icon: "doc.text.fill")
            ]
        case "DISGUSTED":
            techniques = [
                MoodTechnique(text: "Identify the exact source of the disgust and step away from it if possible.", icon: "hand.thumbsdown.fill"),
                MoodTechnique(text: "Practice self-care: wash your face or hands, or change your environment entirely.", icon: "drop.fill"),
                MoodTechnique(text: "Focus on something beautiful or pleasant in your immediate vicinity to counter the feeling.", icon: "sun.max.fill")
            ]
        case "BAD": // General negative/low
            techniques = [
                MoodTechnique(text: "Take a walk and notice 5 things around you to shift your focus outward.", icon: "figure.walk"),
                MoodTechnique(text: "Do something small that you enjoy, like drinking a favorite tea or watching a funny clip.", icon: "mug.fill"),
                MoodTechnique(text: "Remind yourself that it's okay to feel bad, and this feeling is temporary.", icon: "cloud.rain.fill")
            ]
        default:
            techniques = [
                MoodTechnique(text: "Focus on your current emotional state. What does it feel like?", icon: "leaf.fill")
            ]
        }
        
        // Randomly select one technique from the list
        return techniques.randomElement() ?? MoodTechnique(text: "Focus on your current emotional state.", icon: "leaf.fill")
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
                // text rotation
                let textRotation = Angle(degrees: mid)
                
                
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
                
                // TEXT LABELS
                Text(feelings[i])
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    // Position text radially
                    .offset(x: 110 * CGFloat(cos(rad)),
                            y: 110 * CGFloat(sin(rad)))
                    // Rotate text to follow the curve
                    .rotationEffect(.degrees(textRotation.degrees + 90))
                    // Apply the same explosion offset as the segment
                    .offset(x: dx, y: dy)
                    .scaleEffect(isSel && isZooming ? 2.0 : 1.0)
                    .zIndex(isSel && isZooming ? 1 : 0)
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

// MARK: - 4. Technique (Page 3)

struct TechView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Properties to receive the specific mood data from WheelController
    let moodTitle: String
    let techniqueText: String
    let techniqueIcon: String // Will hold "breathe" or "flame.fill"
    var backgroundColor: Color

    var onDone: () -> Void = {}
    
    // Helper function to dynamically load either a custom asset or an SFSymbol
    @ViewBuilder
    private func getIconView(iconName: String) -> some View {
        // If the name does not contain a period, we assume it's a custom image asset name.
        if !iconName.contains(".") {
             // Loads image from your Asset Catalog by name
             Image(iconName)
                 .resizable()
                 .renderingMode(.template) // Allows the foreground color to tint the image
        } else {
             // Loads an icon from the SFSymbol library
             Image(systemName: iconName)
                 .resizable()
        }
    }
    
    var body: some View {
        ZStack {
            // Background is set using the passed-in color
            backgroundColor.opacity(0.25).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Display the selected emotion title
                Text(moodTitle)
                    .font(.custom("Comfortaa-Bold", size: 60))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Use the new dynamic image loader
                getIconView(iconName: techniqueIcon)
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .foregroundColor(backgroundColor) // Icon color matches the emotion color
                    .padding(.bottom, 30)
                
                // Display the correct technique text
                Text(techniqueText)
                    .font(Font.custom("Comfortaa-Bold", size: 26))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Single dot
                Circle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 8)
                    .padding(.bottom, 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Back")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    onDone()
                }
                .fontWeight(.medium)
                .foregroundColor(.primary)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}


// MARK: - 5. Confetti Views

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

// MARK: - 6. Completion View (Page 4)

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
                    .font(.custom("Comfortaa-Bold", size: 34))
                    .fontWeight(.bold)
                
                Text("You have successfully completed the technique.")
                    .font(.custom("Comfortaa-Bold", size: 20))
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
                        .foregroundColor(.black)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    WheelController()
}
