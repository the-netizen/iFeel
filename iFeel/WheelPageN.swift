import SwiftUI
import UIKit

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

// Comfortaa fallback
func comfortaaUIFont(size: CGFloat) -> UIFont {
    for name in ["Comfortaa-Bold","Comfortaa Bold","Comfortaa-bold","Comfortaa"] {
        if let f = UIFont(name: name, size: size) { return f }
    }
    return .systemFont(ofSize: size, weight: .bold)
}

// MARK: - ArcText (proportional spacing + curved)

struct ArcText: View {
    let text: String
    let radiusFactor: CGFloat
    let centerAngle: Double
    let maxSpread: Double
    let minSpread: Double
    let densityDegPerPoint: Double
    let uiFont: UIFont
    let letterSpacingPts: CGFloat
    let color: Color

    init(text: String,
         radiusFactor: CGFloat,
         centerAngle: Double,
         maxSpread: Double,
         minSpread: Double = 14,
         densityDegPerPoint: Double = 0.28,
         uiFont: UIFont,
         letterSpacingPts: CGFloat = 0.9,
         color: Color = .white.opacity(0.94)) {
        self.text = text
        self.radiusFactor = radiusFactor
        self.centerAngle = centerAngle
        self.maxSpread = maxSpread
        self.minSpread = minSpread
        self.densityDegPerPoint = densityDegPerPoint
        self.uiFont = uiFont
        self.letterSpacingPts = letterSpacingPts
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: side/2, y: side/2)
            let rLabel = (side/2) * radiusFactor

            let chars = Array(text)
            let widths: [CGFloat] = chars.map { (String($0) as NSString).size(withAttributes: [.font: uiFont]).width }
            let totalWidthPts = widths.reduce(0, +) + max(0, CGFloat(chars.count - 1)) * letterSpacingPts

            let target = Double(totalWidthPts) * densityDegPerPoint
            let spread = max(minSpread, min(maxSpread, target))

            let anglePerPoint = (totalWidthPts > 0) ? spread / Double(totalWidthPts) : 0
            let startAngle = centerAngle - spread/2

            let centerAngles: [Double] = (0..<chars.count).map { idx in
                let prev = widths.prefix(idx).reduce(0, +) + CGFloat(idx) * letterSpacingPts
                let advance = Double(prev + widths[idx]/2) * anglePerPoint
                return startAngle + advance
            }

            ZStack {
                ForEach(0..<chars.count, id: \.self) { idx in
                    let ang = centerAngles[idx]
                    let theta = CGFloat(ang * .pi / 180)
                    let x = center.x + rLabel * cos(theta)
                    let y = center.y + rLabel * sin(theta)

                    Text(String(chars[idx]))
                        .font(Font(uiFont))
                        .foregroundStyle(color)
                        .shadow(color: .black.opacity(0.55), radius: 3, x: 0, y: 1.5)
                        .shadow(color: .black.opacity(0.18), radius: 6)
                        .rotationEffect(.degrees(ang + 90))
                        .position(x: x, y: y)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - 2) DetailScreen — كما هو (بدون تغيير)
struct DetailScreen: View {
    let titleTop: String
    let allTitles: [String]
    let allColors: [Color]
    let startIndex: Int
    var onStart: (_ mood: String, _ color: Color) -> Void = { _,_ in }

    // الشكل/الأبعاد
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

    // تصحيح محور الدوران والميل
    var wheelAnchorXUnit: CGFloat = 0.47
    var wheelAnchorYUnit: CGFloat = 1.10
    var heroXShift: CGFloat      = -133

    // ناب السناب
    private let spring = (stiffness: 70.0, damping: 10.0)

    @State private var currentIndex: Int = 0
    @State private var wheelAngle: Double = 0
    @State private var lastAngle: Double?

    @Environment(\.dismiss) private var dismiss

    init(titleTop: String,
         allTitles: [String],
         allColors: [Color],
         startIndex: Int,
         onStart: @escaping (_ mood: String, _ color: Color) -> Void = { _,_ in }) {
        self.titleTop = titleTop
        self.allTitles = allTitles
        self.allColors = allColors
        self.startIndex = startIndex
        self.onStart = onStart
        _currentIndex = State(initialValue: max(0, min(startIndex, allTitles.count - 1)))
    }

    private var stepAngle: Double { 360.0 / Double(allTitles.count) }

    private func shortestDelta(_ a: Double, _ b: Double) -> Double {
        var d = b - a
        d = (d + 180).truncatingRemainder(dividingBy: 360) - 180
        return d
    }

    private func angleDegAroundPivot(at p: CGPoint, in size: CGSize) -> Double {
        let cx = size.width  * wheelAnchorXUnit
        let cy = size.height * wheelAnchorYUnit
        return atan2(Double(p.y - cy), Double(p.x - cx)) * 180 / .pi
    }

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
                                .foregroundStyle(.black)
                        }
                        .tint(.black)
                        Spacer()
                    }
                    .padding(.horizontal)

                    VStack(spacing: 6) {
                        Text(titleTop).font(Font.custom("Comfortaa-bold", size: 28))
                        Text(allTitles[currentIndex].uppercased())
                            .font(.system(size: 60, weight: .heavy))
                    }
                }
                .padding(.top, titleTopPadding)
            }

            bottomOverlay
        }
        .navigationBarBackButtonHidden(true)
    }

    private var hero: some View {
        GeometryReader { geo in
            let span = sliceSpanDeg
            let start = -90.0 - span/2
            let end   = -90.0 + span/2
            let nSpan = span * neighborsSpanScale

            ZStack {
                Circle()
                    .fill(allColors[currentIndex].opacity(glowOpacity))
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
                    .fill(allColors[currentIndex])
                    .frame(width: heroDiameter, height: heroDiameter)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            }
            .frame(width: heroDiameter, height: heroDiameter)
            .rotationEffect(.degrees(wheelAngle),
                            anchor: UnitPoint(x: wheelAnchorXUnit, y: wheelAnchorYUnit))
            .offset(x: heroXShift)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { v in
                        let now = angleDegAroundPivot(at: v.location, in: geo.size)
                        if let prev = lastAngle {
                            wheelAngle += shortestDelta(prev, now)
                        }
                        lastAngle = now
                    }
                    .onEnded { _ in
                        let pages = Int( (wheelAngle / stepAngle).rounded() )
                        withAnimation(.interpolatingSpring(stiffness: spring.stiffness,
                                                           damping: spring.damping)) {
                            wheelAngle = Double(pages) * stepAngle
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            if pages != 0 {
                                let c = allTitles.count
                                currentIndex = (currentIndex - pages + c) % c
                            }
                            wheelAngle = 0
                            lastAngle = nil
                        }
                    }
            )
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

            Button(action: {
                onStart(allTitles[currentIndex].uppercased(), allColors[currentIndex])
            }) {
                Text("START")
                    .font(Font.custom("Comfortaa-bold", size: 22))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(allColors[currentIndex])
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .offset(y: startButtonOffset)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - 3) WheelController (Page 1) — مضاف matchedGeometryEffect
struct WheelController: View {
    private let n = 7
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .fuchsia]
    private let titles  = ["Angry","Bad","Happy","Disgusted","Sad","Fearful","Surprised"]

    private let iFeelText: String = "iFeel"
    private let iFeelTopPadding: CGFloat = 20
    private let iFeelLeadingPadding: CGFloat = 30

    private let promptTopText: String = "How Do You"
    private let promptTopOffsetY: CGFloat = -50

    private let promptBottomText: String = "Feel?"
    private let promptBottomOffsetY: CGFloat = 44

    private let hubDiameter: CGFloat = 0
    private let hubOffsetY: CGFloat = 0

    private let wheelStackTopPadding: CGFloat = 24
    private let wheelStackSpacing: CGFloat = 12

    @State private var selected: Int? = nil
    @State private var wheelRotation: Double = 0
    @State private var isZooming: Bool = false
    @State private var goDetail: Bool = false
    @State private var showTechniquePage: Bool = false
    @State private var showCompletionPage: Bool = false

    // سحب العجلة
    @State private var isDragging = false
    @State private var prevDragAngle: Double? = nil

    // ✅ Namespace اختياري للمطابقة
    var matchedNS: Namespace.ID? = nil
    private let showHubMatchedDot: Bool = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                // iFeel title (matched)
               
                Text(iFeelText)
                    .font(Font.custom("Comfortaa-bold", size: 20))
                    .ifLet(matchedNS) { view, ns in
                        view.matchedGeometryEffect(id: "iFeelTitle", in: ns)
                    }
                    .padding(.top, 20)       // ← المسافة من الأعلى
                    .padding(.leading, 20)   // ← المسافة من اليسار



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
                            Text("Tap")
                                .font(Font.custom("Comfortaa-bold", size: 30))
                                .offset(y: hubOffsetY)
                                .allowsHitTesting(false)
                        }
                        wheel
                    }

                    // ✅ نقطة التطابق (هدف دائرة السبلش)
                    if showHubMatchedDot, let ns = matchedNS {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                            .matchedGeometryEffect(id: "coreDot", in: ns)
                            .allowsHitTesting(false)
                            .overlay(Circle().stroke(Color.clear, lineWidth: 0.1))
                            .padding(.top, -36) // عدّليها حسب مكان العجلة
                            .opacity(0.01)
                    }

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
                        allTitles: titles,
                        allColors: colors,
                        startIndex: i,
                        onStart: { mood, _ in
                            if let idx = titles.firstIndex(where: { $0.uppercased() == mood }) {
                                selected = idx
                            }
                            showTechniquePage = true
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $showTechniquePage) {
                if let i = selected {
                    let mood = titles[i].uppercased()
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
                CompletionView(
                    onDone: navigateBackToRoot,
                    themeColor: (selected.map { colors[$0] }) ?? .black
                )
            }
        }
    }

    private func navigateBackToRoot() {
        // أغلق السلسلة
        showCompletionPage = false
        showTechniquePage = false
        goDetail = false

        // ✅ أعيدي ضبط حالة العجلة بالكامل
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            selected = nil
            wheelRotation = 0
            isZooming = false
        }
    }


    // MARK: helpers (محلية للـ WheelController)

    private func angleDeg(at p: CGPoint, in size: CGSize) -> Double {
        let c = CGPoint(x: size.width/2, y: size.height/2)
        return atan2(Double(p.y - c.y), Double(p.x - c.x)) * 180 / .pi
    }

    private func shortestDelta(from a: Double, to b: Double) -> Double {
        var d = b - a
        d = (d + 180).truncatingRemainder(dividingBy: 360) - 180
        return d
    }

    private func angleDegSafe(at p: CGPoint, in size: CGSize, fallback: Double?) -> Double {
        let c = CGPoint(x: size.width/2, y: size.height/2)
        let dx = Double(p.x - c.x), dy = Double(p.y - c.y)
        let r = sqrt(dx*dx + dy*dy)
        let minR = Double(min(size.width, size.height)) * 0.18
        if r < minR, let f = fallback { return f }
        return atan2(dy, dx) * 180 / .pi
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

    // ---------- WHEEL ----------
    private var wheel: some View {
        let step = 360.0 / Double(n)
        let uiFont = comfortaaUIFont(size: 16)
        let labelRadiusFactor: CGFloat = 0.80
        let safetyMarginDeg = 22.0
        _ = max(10.0, step - safetyMarginDeg)

        return GeometryReader { geo in
            let size = geo.size

            ZStack {
                ForEach(0..<n, id: \.self) { i in
                    let start = Double(i) * step
                    let end   = Double(i + 1) * step
                    let mid   = (start + end) / 2.0
                    let rad   = mid * .pi / 180
                    let isSel = (selected == i)
                    let dx = isSel ? 18 * CGFloat(cos(rad)) : 0
                    let dy = isSel ? 18 * CGFloat(sin(rad)) : 0

                    let wedge = RingWedge(startDeg: start, endDeg: end, innerRadiusFactor: 0.58, gapDegrees: 5.0)

                    wedge
                        .fill(colors[i])
                        .compositingGroup()
                        .shadow(color: .black.opacity(0.30), radius: 8, y: 4)
                        .overlay( wedge.stroke(.white.opacity(0.9), lineWidth: 1) )
                        .overlay(
                            ArcText(
                                text: titles[i],
                                radiusFactor: labelRadiusFactor,
                                centerAngle: mid,
                                maxSpread: 40,
                                minSpread: 12,
                                densityDegPerPoint: 0.50,
                                uiFont: uiFont,
                                letterSpacingPts: 0.9,
                                color: .white.opacity(0.95)
                            )
                        )
                        .contentShape(wedge)
                        .offset(x: dx, y: dy)
                        .scaleEffect(isSel && isZooming ? 2.0 : 1.0)
                        .zIndex(isSel && isZooming ? 1 : 0)
                        .onTapGesture { handleTap(index: i, mid: mid) }
                }
            }
            .frame(width: 280, height: 280, alignment: .center)
            .rotationEffect(.degrees(wheelRotation))
            .contentShape(Circle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        let ang = angleDegSafe(at: value.location, in: size, fallback: prevDragAngle)
                        if !isDragging { isDragging = true; prevDragAngle = ang; return }
                        guard let prev = prevDragAngle else { prevDragAngle = ang; return }
                        var d = shortestDelta(from: prev, to: ang)
                        if abs(d) > 45 { prevDragAngle = ang; return }
                        wheelRotation += d
                        prevDragAngle = ang
                    }
                    .onEnded { _ in
                        isDragging = false
                        prevDragAngle = nil
                    }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: wheelRotation)
            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: isZooming)
        }
        .frame(width: 280, height: 280)
    }

    // دوران حسب الجهة
    private func handleTap(index i: Int, mid: Double) {
        let already = (selected == i)
        selected = already ? nil : i
        guard !already else { return }

        let world = mid + wheelRotation
        let shortest = ((-90.0 - world + 180).truncatingRemainder(dividingBy: 360)) - 180
        let deltaCCW = shortest >= 0 ? shortest : shortest + 360
        let deltaCW  = shortest <= 0 ? shortest : shortest - 360
        let theta = world * .pi / 180
        let isRightSide = cos(theta) >= 0
        let chosen = isRightSide ? deltaCCW : deltaCW

        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            wheelRotation += chosen
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) { isZooming = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.00) {
            goDetail = true
            isZooming = false
        }
    }
}
// MARK: - Wheel Close up(Page 2)

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
                        Text(titleTop).font(.system(size: 28, weight: .medium))
                        Text(mood.uppercased()).font(.system(size: 60, weight: .heavy))
                    }
                }
                .padding(.top, titleTopPadding)
            }
            bottomOverlay
        }
        .navigationBarBackButtonHidden(false)
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
                    .font(.system(size: 22, weight: .semibold))
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

// MARK: - 4) Technique (Page 3) — كما كان (مختصر: نفس كودك)
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
        let summary: String
        let details: [String]
        let prompt: String
    }

    private static let poolByMood: [String: [Technique]] = [
        "ANGRY": [
            .init(
                text: "Focused Breathing",
                icon: "wind",
                summary: "Slow, deep breathing to calm the body’s stress response.",
                details: [
                    "Sit or stand tall.",
                    "Inhale slowly through your nose for 4 seconds.",
                    "Exhale through your mouth for 6 seconds.",
                    "Focus only on your breath—nothing else.",
                    "Repeat 5–10 times."
                ],
                prompt: "I breathe in calm, I breathe out tension."
            ),
            .init(
                text: "Cognitive Reappraisal",
                icon: "brain.head.profile",
                summary: "Reframing how you interpret the anger-triggering situation.",
                details: [
                    "Identify the thought fueling your anger (“They did that on purpose”).",
                    "Ask: “Is there another explanation?”",
                    "Rephrase it into something neutral (“Maybe they’re stressed or unaware”).",
                    "Decide whether reacting in anger helps or harms."
                ],
                prompt: "Maybe there’s more to this than I think."
            ),
            .init(
                text: "Time-Out Technique",
                icon: "timer",
                summary: "Taking a brief pause from the trigger to regain control.",
                details: [
                    "Acknowledge: “I’m angry right now.”",
                    "Step away for a few minutes.",
                    "Go outside, breathe, or walk.",
                    "Return once calm enough to think clearly."
                ],
                prompt: "I step back now so I can return wiser."
            ),
            .init(
                text: "Progressive Muscle Relaxation (PMR)",
                icon: "bolt.heart",
                summary: "Tensing and releasing muscles to discharge physical tension.",
                details: [
                    "Focus on one muscle group (e.g., hands).",
                    "Tense for 5 seconds, then release.",
                    "Move through other groups—arms, shoulders, legs.",
                    "Notice how relaxation spreads through your body."
                ],
                prompt: "I release tension and feel lighter."
            )
        ],
        "FEARFUL": [
            .init(
                text: "Gradual Exposure",
                icon: "figure.walk",
                summary: "Facing fears in small, manageable doses until anxiety fades.",
                details: [
                    "List what scares you, from mild to intense.",
                    "Start with the least scary version.",
                    "Stay in it long enough to notice the fear drop.",
                    "Move up the ladder slowly over time."
                ],
                prompt: "I face a little fear today, and it loses power."
            ),
            .init(
                text: "Grounding (5-4-3-2-1)",
                icon: "hand.raised.fill",
                summary: "Using your senses to anchor yourself in the present.",
                details: [
                    "Name 5 things you can see.",
                    "4 things you can touch.",
                    "3 things you can hear.",
                    "2 things you can smell.",
                    "1 thing you can taste."
                ],
                prompt: "I am here, now, and I am safe."
            ),
            .init(
                text: "Positive Imagery Rehearsal",
                icon: "sparkles",
                summary: "Mentally rehearsing success in feared situations.",
                details: [
                    "Close your eyes and imagine the situation.",
                    "Visualize yourself calm and in control.",
                    "Feel your body relaxed as you succeed.",
                    "Replay this scene often."
                ],
                prompt: "I see myself calm, capable, and steady."
            ),
            .init(
                text: "Cognitive Restructuring",
                icon: "list.bullet.rectangle.portrait.fill",
                summary: "Challenging irrational fear-based thoughts.",
                details: [
                    "Write the fearful thought (“I’ll embarrass myself”).",
                    "Ask for evidence for and against it.",
                    "Replace it with a balanced one (“It’s okay to be nervous; I’ll still do fine”).",
                    "Read it aloud when fear returns."
                ],
                prompt: "I replace fear with truth."
            )
        ],
        "SAD": [
            .init(
                text: "Affect Labeling",
                icon: "text.quote",
                summary: "Naming your emotion to reduce its intensity.",
                details: [
                    "Pause and notice your feeling.",
                    "Say: “I’m feeling sad right now.”",
                    "Observe how naming it softens it.",
                    "Write it down if you prefer."
                ],
                prompt: "I name my sadness, and it loosens its grip."
            ),
            .init(
                text: "Behavioral Activation",
                icon: "figure.walk.circle",
                summary: "Doing small positive actions even if you don’t feel like it.",
                details: [
                    "Pick one simple activity (walk, shower, text a friend).",
                    "Commit to doing it fully.",
                    "Track how you feel before and after.",
                    "Add another small action tomorrow."
                ],
                prompt: "I’ll take one small step today."
            ),
            .init(
                text: "Gratitude Journal",
                icon: "book.closed.fill",
                summary: "Writing what you’re grateful for to shift focus from loss to abundance.",
                details: [
                    "Write 3 things you’re grateful for daily.",
                    "Include small details (sunlight, good coffee, friend’s message).",
                    "Re-read them weekly."
                ],
                prompt: "I notice the good—even when it’s small."
            ),
            .init(
                text: "Self-Compassion Break",
                icon: "heart.fill",
                summary: "Treating yourself kindly instead of self-criticizing.",
                details: [
                    "Acknowledge: “This is hard right now.”",
                    "Place your hand on your heart.",
                    "Say: “I’m not alone; others feel this too.”",
                    "Speak gently: “May I be kind to myself.”"
                ],
                prompt: "I give myself the same care I’d give a friend."
            )
        ],
        "BAD": [
            .init(
                text: "Cognitive Reframing",
                icon: "arrow.2.squarepath",
                summary: "Shifting from “everything’s bad” to a more balanced perspective.",
                details: [
                    "Write what feels bad.",
                    "Identify what’s within your control.",
                    "Find one neutral or good aspect.",
                    "Reword your thought: “Some parts are tough, but not all.”"
                ],
                prompt: "Not everything’s bad—some things still work."
            ),
            .init(
                text: "Socratic Questioning",
                icon: "questionmark.circle",
                summary: "Using logical questioning to test your negative assumptions.",
                details: [
                    "Ask: “Is this 100% true?”",
                    "What’s the evidence against it?",
                    "What’s a more realistic thought?",
                    "Keep refining until balanced."
                ],
                prompt: "What else might be true?"
            ),
            .init(
                text: "Behavioral Experiment",
                icon: "chart.bar.xaxis",
                summary: "Testing your negative beliefs through small real-world actions.",
                details: [
                    "Write: “If I try, nothing will change.”",
                    "Do one small opposite action.",
                    "Observe the result—did something shift?",
                    "Use that evidence next time."
                ],
                prompt: "I’ll test it, not assume it."
            ),
            .init(
                text: "Mindful Acceptance",
                icon: "leaf.fill",
                summary: "Allowing negative feelings to exist without fighting them.",
                details: [
                    "Notice your sensations without labeling “good/bad.”",
                    "Breathe slowly.",
                    "Say: “This feeling is here, but it will pass.”",
                    "Let it fade naturally."
                ],
                prompt: "I allow it, and it moves through."
            )
        ],
        "DISGUSTED": [
            .init(
                text: "Psychological Distancing",
                icon: "scope",
                summary: "Observing the situation as if you’re an outsider.",
                details: [
                    "Mentally step back: “I’m just noticing this.”",
                    "Describe it factually (color, shape, function).",
                    "Avoid emotional words.",
                    "Breathe slowly to stabilize."
                ],
                prompt: "I observe without judgment."
            ),
            .init(
                text: "Reappraisal",
                icon: "text.bubble",
                summary: "Reinterpreting what disgusts you through understanding or context.",
                details: [
                    "Ask: “Why does this disgust me?”",
                    "Is there a logical reason (evolutionary, cultural)?",
                    "Focus on purpose rather than reaction."
                ],
                prompt: "Understanding reduces disgust."
            ),
            .init(
                text: "Imagery Rescripting",
                icon: "wand.and.stars",
                summary: "Altering disturbing mental images into neutral ones.",
                details: [
                    "Picture the unpleasant image.",
                    "Change its color, distance, or brightness.",
                    "Re-imagine it softer, smaller, cleaner.",
                    "Practice until the disgust fades."
                ],
                prompt: "I reshape what I see into calm."
            ),
            .init(
                text: "Gradual Exposure",
                icon: "gauge.with.needle",
                summary: "Controlled exposure to what disgusts you, slowly building tolerance.",
                details: [
                    "Start with a mild version (a photo, a story).",
                    "Stay with it until discomfort drops.",
                    "Gradually increase intensity.",
                    "Repeat until desensitized."
                ],
                prompt: "Each time, it loses its grip."
            )
        ],
        "SURPRISED": [
            .init(
                text: "Reorientation",
                icon: "location.viewfinder",
                summary: "Refocusing quickly on the present facts after being startled.",
                details: [
                    "Stop and breathe.",
                    "Ask: “What exactly just happened?”",
                    "Separate facts from assumptions.",
                    "Act only when you understand clearly."
                ],
                prompt: "I pause, I clarify, I move forward."
            ),
            .init(
                text: "Cognitive Pause",
                icon: "pause.circle.fill",
                summary: "Deliberately delaying your reaction for a few seconds.",
                details: [
                    "Feel the shock.",
                    "Count slowly to three.",
                    "Then respond consciously, not impulsively."
                ],
                prompt: "Pause. Then choose."
            ),
            .init(
                text: "Label and Accept",
                icon: "checkmark.seal",
                summary: "Naming the surprise helps integrate it emotionally.",
                details: [
                    "Say: “I’m surprised.”",
                    "Feel your body’s sensations (heart rate, breath).",
                    "Let it calm naturally."
                ],
                prompt: "I name it. I accept it."
            ),
            .init(
                text: "Positive Reinterpretation",
                icon: "sun.max",
                summary: "Seeing surprises as potential opportunities.",
                details: [
                    "Ask: “Could this be useful somehow?”",
                    "Identify a benefit or lesson.",
                    "Let curiosity replace shock."
                ],
                prompt: "Maybe this change is a hidden opening."
            )
        ],
        "HAPPY": [
            .init(
                text: "Savoring",
                icon: "sun.max.fill",
                summary: "Extending the positive emotion by staying fully in the moment.",
                details: [
                    "When joy appears, stop.",
                    "Notice what you see, hear, and feel.",
                    "Breathe it in slowly.",
                    "Hold the moment before moving on."
                ],
                prompt: "I stay here and enjoy it fully."
            ),
            .init(
                text: "Gratitude Amplification",
                icon: "heart.text.square",
                summary: "Strengthening happiness through appreciation.",
                details: [
                    "Identify who or what contributed to your joy.",
                    "Thank them (mentally or directly).",
                    "Reflect on how lucky you feel."
                ],
                prompt: "Thank you—for this, for now."
            ),
            .init(
                text: "Positive Projection",
                icon: "arrow.up.right.circle.fill",
                summary: "Imagining how current happiness can inspire future growth.",
                details: [
                    "Visualize using your joy as motivation.",
                    "Imagine your next positive action.",
                    "Link emotion with progress."
                ],
                prompt: "This happiness fuels my next move."
            ),
            .init(
                text: "Sharing Joy",
                icon: "person.2.wave.2.fill",
                summary: "Sharing happiness strengthens connection and prolongs it.",
                details: [
                    "Tell someone what made you happy.",
                    "Describe it vividly.",
                    "Watch their smile—let it echo yours."
                ],
                prompt: "I share this joy so it multiplies."
            )
        ]
    ]

    @State private var currentIndex: Int = 0
    private var pool: [Technique] {
        Self.poolByMood[moodTitle.uppercased()] ?? [
            .init(
                text: techniqueText,
                icon: techniqueIcon,
                summary: "Breathe slowly for 1–2 minutes.",
                details: ["Inhale gently", "Exhale longer", "Repeat and relax"],
                prompt: "Easy in, slower out."
            )
        ]
    }
    private var current: Technique { pool[currentIndex] }
    @State private var showDetails = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
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
                    .padding(.bottom, 8)

                VStack(spacing: 6) {
                    Text(current.text)
                        .font(Font.custom("Comfortaa-bold", size: 28))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    Text(current.summary)
                        .font(Font.custom("Comfortaa-bold", size: 17))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)
                }

                Spacer(minLength: 0)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button(action: { showDetails = true }) {
                    HStack(spacing: 8) { Image(systemName: "info.circle") }
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: nextTechnique) {
                    HStack(spacing: 8) { Image(systemName: "shuffle") }
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showDetails) { detailsSheet }
    }

    private func nextTechnique() {
        let next = (currentIndex + 1) % pool.count
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentIndex = next
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var detailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(current.text)
                        .font(Font.custom("Comfortaa-bold", size: 28))
                        .foregroundStyle(backgroundColor)

                    Text(current.summary)
                        .font(Font.custom("Comfortaa-bold", size: 17))
                        .foregroundColor(.secondary)

                    ForEach(current.details, id: \.self) { step in
                        HStack(alignment: .top, spacing: 10) {
                            Circle().fill(backgroundColor).frame(width: 8, height: 8).padding(.top, 8)
                            Text(step)
                                .font(.title3)
                                .foregroundStyle(backgroundColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider().padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prompt")
                            .font(Font.custom("Comfortaa-bold", size: 20))
                            .bold()
                            .foregroundStyle(backgroundColor)
                        Text("“\(current.prompt)”")
                            .font(Font.custom("Comfortaa-bold", size: 19))
                            .bold()
                            .foregroundColor(.primary)
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
// MARK: - Confetti (single source of truth)
fileprivate struct ConfettiUpPiece: View {
    let size: CGSize
    @State private var xPos: CGFloat = 0
    @State private var yPos: CGFloat = 0
    @State private var rotation = Angle.degrees(.random(in: 0...360))
    @State private var opacity: Double = 0.0

    private let color: Color = [.blue, .red, .green, .yellow, .purple, .orange, .pink, .mint].randomElement()!
    private let duration = Double.random(in: 2.5...4.0)

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: .random(in: 6...12), height: .random(in: 8...16))
            .rotationEffect(rotation, anchor: .center)
            .offset(x: xPos, y: yPos)
            .opacity(opacity)
            .onAppear {
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

fileprivate struct ConfettiUpView: View {
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

struct CompletionView: View {
    var onDone: () -> Void = {}
    var themeColor: Color = .black

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // داخل CompletionView body
            ConfettiUpView()

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
import SwiftUI

// MARK: - Splash using static image
struct ImageSplashView: View {
    let matchedNS: Namespace.ID

    // الإعدادات
    var imageName: String = "SplashFlower"
    var size: CGFloat = 260
    var centerOffset: CGSize = .zero

    // سرعة أهدأ للدوران، مع زووم قبل النهاية
    var rotateDuration: Double = 4.5
    var zoomInLead: Double = 0.60   // قبل نهاية الدوران بكم ثانية نبدأ الزووم
    var zoomInDuration: Double = 0.30
    var imageFadeBeforeTitle: Double = 0.15  // نخفي الصورة أولاً (عشان iFeel ما يجي فوقها)
    var titleSpring: (response: Double, damping: Double) = (0.28, 0.95) // أسرع وأسموث

    @State private var rotate: Double = 0
    @State private var imgScale: CGFloat = 1.0
    @State private var imgOpacity: Double = 1.0
    @State private var showTitle: Bool = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            // صورة السبلش (تدور ثم تعمل زووم إن ثم تختفي)
            Image(imageName)
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotate))
                .scaleEffect(imgScale)
                .opacity(imgOpacity)
                .offset(centerOffset)
                .onAppear { runTimeline() }

            // iFeel يظهر فقط بعد إخفاء الصورة (مافي تراكب أبداً)
            if showTitle {
                Text("iFeel")
                    .font(Font.custom("Comfortaa-bold", size: 35))
                    .matchedGeometryEffect(id: "iFeelTitle", in: matchedNS)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
                    .zIndex(10)
                    .allowsHitTesting(false)
            }
        }
    }

    private func runTimeline() {
        // 1) دوران كامل
        withAnimation(.linear(duration: rotateDuration)) {
            rotate = 360
        }

        // 2) Zoom-in قبل النهاية
        let zoomStart = max(0, rotateDuration - zoomInLead)
        DispatchQueue.main.asyncAfter(deadline: .now() + zoomStart) {
            withAnimation(.easeInOut(duration: zoomInDuration)) {
                imgScale = 1.12
            }
        }

        // 3) أخفي الصورة سريعاً، ثم أظهر iFeel (بدون تراكب)
        let hideImageAt = rotateDuration - imageFadeBeforeTitle
        DispatchQueue.main.asyncAfter(deadline: .now() + hideImageAt) {
            withAnimation(.easeIn(duration: imageFadeBeforeTitle)) {
                imgOpacity = 0
            }
            // أعطي مجال 40ms ثم أظهر العنوان بحركة سريعة وسلسة
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                withAnimation(.interpolatingSpring(stiffness: 1/titleSpring.response,
                                                   damping: titleSpring.damping)) {
                    showTitle = true
                }
            }
        }
    }
}

// MARK: - Flower Splash (Pulse + Rotate → Disperse → Pop → iFeel)
struct FlowerSplashView: View {
    // رتّبي الألوان مثل ما تبغين
    private let colors: [Color]  = [.fuchsia, .orange, .yellow, .green, .mint, .blue, .purple]
    let matchedNS: Namespace.ID

    // === مقابض تعديل سريعة ===
    // تموضع مركز الزهرة (حل مشكلة الميل لليمين)
    var centerOffset: CGSize = CGSize(width: -6, height: -6)  // عدّلي X/Y هنا
    // أحجام
    var petalSize: CGSize = CGSize(width: 180, height: 180)
    var radiusInitial: CGFloat = 64
    var radiusDisperse: CGFloat = 90   // ← يفتح الدائرة لتبرز الألوان
    var containerSide: CGFloat = 260

    // سرعات/زمن
    var pulseDuration: Double = 0.9
    var rotateDuration: Double = 4.0   // أسرع/أبطأ دوران
    var disperseDuration: Double = 0.35
    var disperseAngleJitter: Double = 12 // درجات زيادة الفصل بين البتلات
    var popDelayAfterDisperse: Double = 0.18

    // حالات متحركة
    @State private var rotate: Double = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    @State private var blur: CGFloat = 0
    @State private var showTitle: Bool = false
    @State private var radius: CGFloat = 64
    @State private var jitter: Double = 0
    @State private var baseRotation: Double = 0

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    FlowerPetals(
                        colors: colors,
                        petalSize: petalSize,
                        radius: radius,
                        baseRotation: baseRotation + rotate,
                        angleJitter: jitter,
                        scaleEach: 0.98 // تخفيف تداخل بسيط
                    )
                    .frame(width: containerSide, height: containerSide)
                    .scaleEffect(scale)
                    .blur(radius: blur)
                    .opacity(opacity)
                    .offset(centerOffset)            // ← تموضع السبلش كامل
                    .onAppear { runTimeline() }
                }

                if showTitle {
                    Text("iFeel")
                        .font(Font.custom("Comfortaa-bold", size: 34))
                        .matchedGeometryEffect(id: "iFeelTitle", in: matchedNS)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    private func runTimeline() {
        // init
        radius = radiusInitial
        baseRotation = 0
        jitter = 0
        rotate = 0
        scale = 1
        opacity = 1
        blur = 0
        showTitle = false

        // 1) Pulse + Rotate (مكررين مرتين فقط)
        withAnimation(.easeInOut(duration: pulseDuration).repeatCount(2, autoreverses: true)) {
            scale = 1.06
        }
        withAnimation(.linear(duration: rotateDuration)) {
            rotate = 360
        }

        // 2) Disperse: نفتح نصف القطر ونضيف تباين زاوي ليفصل الألوان بوضوح
        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration * 1.1) {
            withAnimation(.spring(response: disperseDuration, dampingFraction: 0.85)) {
                radius = radiusDisperse
                jitter = disperseAngleJitter
                baseRotation = 0 // لو تبين ميل بسيط زيديه
            }
        }

        // 3) Pop (Zoom + blur + fade)
        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration * 1.1 + disperseDuration + popDelayAfterDisperse) {
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 10)) {
                scale = 1.22
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                withAnimation(.easeIn(duration: 0.10)) {
                    scale = 1.45
                    blur = 2
                }
                withAnimation(.easeOut(duration: 0.22)) {
                    scale = 1.85
                    blur = 6
                    opacity = 0
                }
            }
        }

        // 4) Show iFeel
        DispatchQueue.main.asyncAfter(deadline: .now() + pulseDuration * 1.1 + disperseDuration + popDelayAfterDisperse + 0.34) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showTitle = true
            }
        }
    }
}

// MARK: - Petal shape (برد بسيط/نظيف)
struct Petal: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w/2, y: 0))
        p.addQuadCurve(to: CGPoint(x: w, y: h*0.60), control: CGPoint(x: w*0.95, y: h*0.10))
        p.addQuadCurve(to: CGPoint(x: w/2, y: h),    control: CGPoint(x: w,     y: h*0.95))
        p.addQuadCurve(to: CGPoint(x: 0,   y: h*0.60), control: CGPoint(x: 0,     y: h*0.95))
        p.addQuadCurve(to: CGPoint(x: w/2, y: 0),    control: CGPoint(x: w*0.05, y: h*0.10))
        p.closeSubpath()
        return p
    }
}

// MARK: - FlowerPetals (نسخة مطوّرة)
struct FlowerPetals: View {
    let colors: [Color]
    let petalSize: CGSize            // حجم البتلة
    var radius: CGFloat              // نصف قطر التموضع (قابل للأنيميشن)
    var baseRotation: Double = 0     // دوران أساسي للزهرة
    var angleJitter: Double = 0      // تباين زاوي (± درجات لكل بتلة لإظهار الفصل)
    let petalCount: Int = 7
    var scaleEach: CGFloat = 1.0     // تقليص بسيط لتخفيف التداخل

    var body: some View {
        ZStack {
            ForEach(0..<petalCount, id: \.self) { i in
                let step = 360.0 / Double(petalCount)
                // نزح زاوي بسيط على شكل موجة ليفصل الألوان عند التفكك
                let wave = sin((Double(i)/Double(petalCount)) * .pi * 2) * angleJitter
                let ang  = Double(i) * step + baseRotation + wave

                Petal()
                    .fill(colors[i % colors.count])
                    .frame(width: petalSize.width, height: petalSize.height)
                    .scaleEffect(scaleEach)
                    .rotationEffect(.degrees(ang))
                    .offset(y: -radius)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
        }
        .compositingGroup()
    }
}


struct RootAppView: View {
    @Namespace private var ns
    @State private var showSplash: Bool = true

    // نفس القيم لازم تتطابق مع اللي في ImageSplashView (للحساب الزمني)
    private let rotationDuration = 4.0
    private let titleDelay = 1.2

    var body: some View {
        ZStack {
            WheelController(matchedNS: ns)
                .opacity(showSplash ? 0 : 1)
                .animation(.easeOut(duration: 0.35), value: showSplash)

            if showSplash {
                ImageSplashView(
                    matchedNS: ns,
                    imageName: "SplashFlower",
                    size: 260,
                    centerOffset: .zero,
                    rotateDuration: 3.5    // ← كان rotationDuration أو titleDelay سابقاً
                )

                .transition(.opacity)
            }
        }
        .onAppear {
            let rotateDuration = 3.4
            let safety = 0.10
            DispatchQueue.main.asyncAfter(deadline: .now() + rotateDuration + safety) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.95)) {
                    showSplash = false
                }
            }
        }

    }
}




@main
struct iFeelApp: App {
    var body: some Scene {
        WindowGroup {
            RootAppView()
        }
    }
}

// MARK: - Small utility
fileprivate extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

fileprivate extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let unwrapped = value {
            transform(self, unwrapped)
        } else {
            self
        }
    }
}


#Preview { WheelController() }
