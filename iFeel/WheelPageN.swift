import SwiftUI

// MARK: - 1) Helpers

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

// MARK: - 2) DetailScreen (Page 2)

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
                                .foregroundStyle(.black) // Back أسود
                        }
                        .tint(.black)
                        Spacer()
                    }
                    .padding(.horizontal)

                    VStack(spacing: 6) {
                        Text(titleTop).font(Font.custom("Comfortaa-bold", size: 28))
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
                    .font(Font.custom("Comfortaa-bold", size: 22))
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

// MARK: - 3) WheelController (Page 1)

struct WheelController: View {
    private let n = 7
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .fuchsia]
    private let titles  = ["ANGRY","BAD","HAPPY","DISGUSTED","SAD","FEARFUL","SURPRISED"]

    private let iFeelText: String = "iFeel"
    private let iFeelFontSize: CGFloat = 30
    private let iFeelTopPadding: CGFloat = 20
    private let iFeelLeadingPadding: CGFloat = 30

    private let promptTopText: String = "How Do You"
    private let promptTopSize: CGFloat = 55
    private let promptTopOffsetY: CGFloat = -50

    private let promptBottomText: String = "Feel?"
    private let promptBottomSize: CGFloat = 55
    private let promptBottomOffsetY: CGFloat = 44

    private let hubDiameter: CGFloat = 0
    private let hubOffsetY: CGFloat = 0
    private let hubText: String = "Tab"
    private let hubTextSize: CGFloat = 33

    private let wheelStackTopPadding: CGFloat = 24
    private let wheelStackSpacing: CGFloat = 12

    @State private var selected: Int? = nil
    @State private var wheelRotation: Double = 0
    @State private var isZooming: Bool = false
    @State private var goDetail: Bool = false
    @State private var showTechniquePage: Bool = false
    @State private var showCompletionPage: Bool = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Text(iFeelText)
                    .font(Font.custom("Comfortaa-bold", size: 30))
                    .padding(.top, iFeelTopPadding)
                    .padding(.leading, iFeelLeadingPadding)

                VStack(spacing: wheelStackSpacing) {
                    Text(promptTopText)
                        .font(Font.custom("Comfortaa-bold", size: 50))
                        .offset(y: promptTopOffsetY)

                    ZStack {
                        if hubDiameter > 0 {
                            Circle()
                                .fill(Color.white)
                                .frame(width: hubDiameter, height: hubDiameter)
                                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                                .offset(y: hubOffsetY)
                            Text(hubText)
                                .font(Font.custom("Comfortaa-bold", size: 30))
                                .offset(y: hubOffsetY)
                                .allowsHitTesting(false)
                        }
                        wheel
                    }

                    // Feel? بنفس وزن الأعلى (مش بولد)
                    Text(promptBottomText)
                        .font(Font.custom("Comfortaa-bold", size: 55))
                        .offset(y: promptBottomOffsetY)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                .padding(.top, wheelStackTopPadding)
            }
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
                if let i = selected {
                    let mood = titles[i]
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
        }
    }

    private func navigateBackToRoot() {
        showCompletionPage = false
        showTechniquePage = false
        goDetail = false
    }

    private func getTechniqueData(for mood: String) -> (text: String, icon: String) {
        switch mood.uppercased() {
        case "ANGRY":     return ("Box Breathing", "square.grid.2x2")
        case "SAD":       return ("4-7-8 Breathing", "wind")
        case "HAPPY":     return ("Savoring", "sun.max.fill")
        case "FEARFUL":   return ("Physiological Sigh", "lungs.fill")
        case "SURPRISED": return ("3-Beat Pause", "pause.circle.fill")
        case "DISGUSTED": return ("5-4-3-2-1 Grounding", "hand.raised.fill")
        case "BAD":       return ("Three Gratitudes", "heart.text.square")
        default:          return ("Breathe", "leaf.fill")
        }
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

// MARK: - 4) Technique (Page 3) — white bg, Back black, Shuffle sequential, buttons bottom, Details white+colored text

struct TechView: View {
    @Environment(\.dismiss) private var dismiss

    let moodTitle: String
    let techniqueText: String
    let techniqueIcon: String
    var backgroundColor: Color
    var onDone: () -> Void = {}

    struct Technique: Hashable {
        let text: String
        let icon: String
        let details: [String]
    }

    // 4 techniques per mood (بالإنجليزي)
    private static let poolByMood: [String: [Technique]] = [
        "ANGRY": [
            .init(text: "Box Breathing", icon: "square.grid.2x2",
                  details: ["Inhale 4 seconds.", "Hold 4 seconds.", "Exhale 4 seconds.", "Hold 4 seconds.", "Repeat 4–6 cycles."]),
            .init(text: "Progressive Muscle Release", icon: "bolt.heart",
                  details: ["Tense 5 seconds.", "Release 10 seconds.", "Repeat 2–3 rounds.", "Switch to next muscle group."]),
            .init(text: "Cognitive Reframe", icon: "pencil",
                  details: ["Write the trigger.", "Reframe with a calmer, equally true thought.", "Repeat new statement for 60 seconds."]),
            .init(text: "Count Backwards", icon: "number.square.fill",
                  details: ["Count 50 → 0 by 3s.", "Breathe slowly while counting."])
        ],
        "BAD": [
            .init(text: "Three Gratitudes", icon: "heart.text.square",
                  details: ["List 3 specific things.", "Write one sentence each."]),
            .init(text: "2-Minute Body Shake", icon: "figure.run",
                  details: ["Shake arms/legs/shoulders for 120 seconds.", "Finish with 3 slow breaths."]),
            .init(text: "Hydrate & Stretch", icon: "drop.fill",
                  details: ["Drink a full glass of water.", "Neck/shoulder stretch 20–30 seconds each side."]),
            .init(text: "Open Air Reset", icon: "leaf.fill",
                  details: ["Step outside 3–5 minutes.", "Notice temperature, light, sounds."])
        ],
        "HAPPY": [
            .init(text: "Savoring", icon: "sun.max.fill",
                  details: ["Recall a positive moment.", "Describe sensory details for 30–60 seconds."]),
            .init(text: "Share the Joy", icon: "person.2.wave.2.fill",
                  details: ["Tell someone what happened.", "Explain why it matters to you."]),
            .init(text: "Small Act of Kindness", icon: "hand.thumbsup.fill",
                  details: ["Pick one tiny helpful act.", "Do it within the next hour."]),
            .init(text: "Photo Recall", icon: "photo.fill",
                  details: ["Open a photo that makes you smile.", "Name what you appreciate in it."])
        ],
        "DISGUSTED": [
            .init(text: "5-4-3-2-1 Grounding", icon: "hand.raised.fill",
                  details: ["5 see", "4 feel", "3 hear", "2 smell", "1 taste."]),
            .init(text: "Clean & Soothe", icon: "drop.triangle.fill",
                  details: ["Wash hands/face 30–60 seconds.", "Use a calming scent (lavender/mint)."]),
            .init(text: "Label the Thought", icon: "tag.fill",
                  details: ["Say: “I’m noticing disgust thoughts.”", "Describe without judging."]),
            .init(text: "Neutral Focus", icon: "circle.lefthalf.fill",
                  details: ["Pick a neutral object.", "Track edges and colors for 60 seconds."])
        ],
        "SAD": [
            .init(text: "4-7-8 Breathing", icon: "wind",
                  details: ["Inhale 4 seconds.", "Hold 7 seconds.", "Exhale 8 seconds.", "Repeat 4–6 cycles."]),
            .init(text: "Name It to Tame It", icon: "text.quote",
                  details: ["Label precisely (sad/lonely/disappointed).", "Say it once out loud."]),
            .init(text: "Tiny Mood Lifts", icon: "checkmark.circle.fill",
                  details: ["List 3 tiny actions.", "Do one now for 2–5 minutes."]),
            .init(text: "Warm Comfort", icon: "mug.fill",
                  details: ["Warm drink.", "Sit in sunlight/lamplight 5–10 minutes."])
        ],
        "FEARFUL": [
            .init(text: "Physiological Sigh", icon: "lungs.fill",
                  details: ["Short inhale.", "Second quick inhale.", "Long exhale.", "Repeat ×5."]),
            .init(text: "Safety Statements", icon: "shield.lefthalf.filled",
                  details: ["What is in my control now?", "Write one action.", "Schedule/do it today."]),
            .init(text: "Evidence Check", icon: "list.bullet.rectangle.portrait.fill",
                  details: ["3 for.", "3 against.", "Pick the realistic next step."]),
            .init(text: "Box Visual", icon: "square.on.square",
                  details: ["Visualize a safe box around you.", "Breathe slowly for 60 seconds."])
        ],
        "SURPRISED": [
            .init(text: "3-Beat Pause", icon: "pause.circle.fill",
                  details: ["Notice body & breath.", "One slow inhale/exhale.", "Choose next action."]),
            .init(text: "Micro-Journal", icon: "book.closed.fill",
                  details: ["What changed? (2–3 lines).", "One feeling, one need."]),
            .init(text: "Pick the Next Step", icon: "arrowshape.turn.up.right.fill",
                  details: ["List 2–3 actions.", "Start the smallest now."]),
            .init(text: "Orienting", icon: "location.viewfinder",
                  details: ["Look left/center/right slowly.", "Name what you see."])
        ]
    ]

    @State private var currentIndex: Int
    private let pool: [Technique]
    private var current: Technique { pool[currentIndex] }
    @State private var showDetails = false

    init(moodTitle: String,
         techniqueText: String,
         techniqueIcon: String,
         backgroundColor: Color,
         onDone: @escaping () -> Void = {}) {
        self.moodTitle = moodTitle
        self.backgroundColor = backgroundColor
        self.onDone = onDone
        self.techniqueText = techniqueText
        self.techniqueIcon = techniqueIcon

        let key = moodTitle.uppercased()
        let fallback = Technique(text: techniqueText, icon: techniqueIcon, details: ["Breathe slowly for 1–2 minutes."])
        let p = Self.poolByMood[key] ?? [fallback]
        self.pool = p
        _currentIndex = State(initialValue: 0) // ابدأ من الأول ولف بالترتيب
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 32) {
                // Top bar (Back أسود)
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold))
                            
                        }
                    }
                    .foregroundStyle(.black)
                    Spacer()
                    Button("Done") { onDone() }
                        .foregroundStyle(.black)
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer(minLength: 10)

                Text(moodTitle)
                    .font(Font.custom("Comfortaa-bold", size: 35))
                    .foregroundColor(.primary)

                Image(systemName: current.icon)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 200)
                    .foregroundColor(backgroundColor)
                    .padding(.bottom, 12)

                Text(current.text)
                    .font(Font.custom("Comfortaa-bold", size: 28))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 36)

                Spacer(minLength: 0)
            }
        }
        // أزرار Shuffle + More Details تحت
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button(action: { showDetails = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                        //Text("More Details")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: nextTechnique) {
                    HStack(spacing: 8) {
                        Image(systemName: "shuffle")
                        //Text("Shuffle")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
           // .background(.regularMaterial) // يبان واضح ومثبت تحت
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showDetails) { detailsSheet }
    }

    // يمشي بالترتيب (0→1→2→3→0 ...)
    private func nextTechnique() {
        let next = (currentIndex + 1) % pool.count
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentIndex = next
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // صفحة التفاصيل: بيضاء، والنص ملون بلون الشعور + خط أكبر
    private var detailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(current.text)
                        .font(.title.bold())                 // أكبر
                        .foregroundStyle(backgroundColor)    // ملوّن
                        .padding(.bottom, 8)

                    ForEach(current.details, id: \.self) { step in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(backgroundColor).frame(width: 8, height: 8).padding(.top, 8)
                            Text(step)
                                .font(.title3)               // أكبر
                                .foregroundStyle(backgroundColor) // ملوّن
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("How to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showDetails = false }
                        .foregroundStyle(.black)
                }
            }
        }
    }
}

// MARK: - 5) Confetti Upwards (from bottom to top)

struct ConfettiUpPiece: View {
    let size: CGSize
    @State private var xPos: CGFloat = 0
    @State private var yPos: CGFloat = 0
    @State private var rotation = Angle.degrees(.random(in: 0...360))
    @State private var opacity: Double = 0.0

    let color: Color = [.blue, .red, .green, .yellow, .purple, .orange, .pink, .mint].randomElement()!
    let duration = Double.random(in: 2.5...4.0)

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: .random(in: 6...12), height: .random(in: 8...16))
            .rotationEffect(rotation, anchor: .center)
            .offset(x: xPos, y: yPos)
            .opacity(opacity)
            .onAppear {
                // ابدأ من أسفل واطلع لفوق
                xPos = .random(in: -size.width/2 ... size.width/2)
                yPos = size.height/2 + .random(in: 20...120)

                withAnimation(.linear(duration: 0.25)) { opacity = 1.0 }
                withAnimation(.linear(duration: duration).delay(0.05)) {
                    yPos = -size.height/2 - 80
                    xPos += .random(in: -120...120)
                    rotation += Angle(degrees: .random(in: 360...1080))
                }
                withAnimation(.linear(duration: 0.6).delay(duration - 0.6)) { opacity = 0 }
            }
    }
}

struct ConfettiUpView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<150, id: \.self) { _ in
                    ConfettiUpPiece(size: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - 6) Completion View (Page 4)

struct CompletionView: View {
    var onDone: () -> Void = {}
    var themeColor: Color = .black

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ConfettiUpView()   // تطلع لفوق

            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 80))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, themeColor)

                Text("Well Done!")
                    .font(Font.custom("Comfortaa-bold", size: 42))
                    .fontWeight(.bold)

                Text("You have successfully completed the technique.")
                    .font(Font.custom("Comfortaa-bold", size: 22))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onDone){
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .foregroundColor(.black)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview { WheelController() }
