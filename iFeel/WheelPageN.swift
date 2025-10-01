//
//  ContentView.swift
//  test
//
//  Created by Noura Faiz Alfaiz on 28/09/2025.
//
import SwiftUI

// MARK: - Helpers

extension Color {
    /// فوشي حقيقي (مو وردي باهت)
    static let fuchsia = Color(red: 1.00, green: 0.18, blue: 0.61) // تقريبًا #FF2D9B
}

// قطاع حلقي (دونات)
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
        let s = startDeg * .pi / 180 + g      // 0° عند اليمين
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

    private let innerFactor: CGFloat = 0.58
    private let gapDeg: Double = 5.0
    private let explodeDistance: CGFloat = 18

    @State private var selected: Int? = nil
    @State private var wheelRotation: Double = 0
    @State private var isZooming: Bool = false
    @State private var goDetail: Bool = false

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
                            onStart: { /* TODO */ }
                        )
                    }
                }
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
                let dx = isSel ? explodeDistance * CGFloat(cos(rad)) : 0
                let dy = isSel ? explodeDistance * CGFloat(sin(rad)) : 0

                RingWedge(startDeg: start, endDeg: end,
                          innerRadiusFactor: innerFactor, gapDegrees: gapDeg)
                    .fill(colors[i])
                    .compositingGroup() // مهم قبل الظل عشان ينعمل على الشكل كامل
                    .shadow(color: .black.opacity(0.30), radius: 8, y: 4) // ظل تحت شرائح العجلة
                    .overlay(
                        RingWedge(startDeg: start, endDeg: end,
                                  innerRadiusFactor: innerFactor, gapDegrees: gapDeg)
                            .stroke(.white.opacity(0.9), lineWidth: 1)
                    )
                    .offset(x: dx, y: dy)                    // انفجار
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

    /// انفجار → تدوير للأعلى → زوم → انتقال
    private func handleTap(index i: Int, mid: Double) {
        let already = (selected == i)
        selected = already ? nil : i
        guard !already else { return }

        let currentWorldAngle = mid + wheelRotation
        let delta = -90.0 - currentWorldAngle
        let normalizedDelta = ((delta + 180).truncatingRemainder(dividingBy: 360)) - 180

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                wheelRotation += normalizedDelta
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + 0.55) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                isZooming = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28 + 0.55 + 0.45) {
            goDetail = true
            isZooming = false
        }
    }
}

// MARK: - Detail (Page 2)

struct DetailScreen: View {
    let titleTop: String
    let mood: String
    let color: Color
    var onStart: () -> Void = {}

    // ===== KNOBS =====
    var titleTopPadding: CGFloat = 330      // ↓ نزّل النص فقط
    var heroTop: CGFloat = 570             // ↓ نزّل الشكل (مستقل عن النص)
    var heroDiameter: CGFloat = 750        // حجم الشكل
    var sliceSpanDeg: Double = 85          // عرض المثلث
    var sliceInnerFactor: CGFloat = 0.20   // سماكة: أصغر = أسمك

    // المثلثات الرمادية (لصق + ميل):
    var neighborsSpanScale: Double = 0.88  // نسبة عرض الجار
    var neighborsGapDeg: Double = 1.5      // فجوة صغيرة (التصاق)
    var neighborsOffsetDeg: Double = -6     // ميل يمين/يسار

    // الإضاءة الخلفية:
    var glowOpacity: Double = 0.35
    var glowBlur: CGFloat = 55

    // الدائرة + الزر:
    var bottomCircleScale: CGFloat = 1.2
    // KNOB
    var bottomYOffsetFactor: CGFloat = 0.93  // جرّب 0.68 أو 0.72
    var startButtonOffset: CGFloat = 280    // ↓ نزّل زر START
    // ==================

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            // نص وهدَر بطبقة
            ZStack(alignment: .top) {
                // الشكل بطبقة مستقلة ومثبت من الأعلى
                hero
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, heroTop)

                // الهيدر + النص (لا يحرّك الشكل)
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
                .padding(.top, titleTopPadding) // ← يحرك النص فقط
            }

            // نصف دائرة + زر (Overlay سفلي مستقل)
            bottomOverlay
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Pieces

    private var hero: some View {
        ZStack {
            let span = sliceSpanDeg
            let start = -90.0 - span/2
            let end   = -90.0 + span/2
            let nSpan = span * neighborsSpanScale

            // Glow خلفي
            Circle()
                .fill(color.opacity(glowOpacity))
                .frame(width: heroDiameter * 0.9, height: heroDiameter * 0.9)
                .blur(radius: glowBlur)
                .blendMode(.plusLighter)
                .offset(y: 8)

            // جار يسار (ملاصق مع تحكم الميل)
            RingWedge(startDeg: start - neighborsOffsetDeg - nSpan,
                      endDeg:   start - neighborsOffsetDeg,
                      innerRadiusFactor: sliceInnerFactor,
                      gapDegrees: neighborsGapDeg)
                .fill(Color.black.opacity(0.16))
                .frame(width: heroDiameter, height: heroDiameter)

            // جار يمين
            RingWedge(startDeg: end + neighborsOffsetDeg,
                      endDeg:   end + neighborsOffsetDeg + nSpan,
                      innerRadiusFactor: sliceInnerFactor,
                      gapDegrees: neighborsGapDeg)
                .fill(Color.black.opacity(0.16))
                .frame(width: heroDiameter, height: heroDiameter)

            // المثلث الأساسي
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
                    .font(.system(size: 22, weight: .semibold))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(color)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .offset(y: startButtonOffset) // ← نزول الزر فعليًا
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview { WheelController() }
