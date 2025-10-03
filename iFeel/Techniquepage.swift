import SwiftUI

//MARK: - Emotion Data Model
struct Emotion {
    let name: String
    let color: Color
    let pages: [(image: String, text: String)]
}

// MARK: - All Emotions
let emotions: [Emotion] = [
    Emotion(
        name: "Sad",
        color: Color(red: 0.2, green: 0.4, blue: 0.9),
        pages: [
            ("Meditate", "Clear your mind and meditate"),
            ("breathe", "Take deep breaths and relax"),
            ("Journal", "Express your thoughts through journaling")
        ]
    ),
    Emotion(
        name: "Angry",
        color: Color(red: 0.9, green: 0.2, blue: 0.2),
        pages: [
            ("Punchbag", "Release anger on a punching bag"),
            ("Run", "Go for a run to burn energy"),
            ("Stretch", "Stretch your body to release tension")
        ]
    ),
    Emotion(
        name: "Disgust",
        color: Color(red: 0.3, green: 0.7, blue: 0.3),
        pages: [
            ("MindfulBreathing", "Practice deep breathing to center yourself"),
            ("Nature", "Walk outside for fresh air")
        ]
    ),
    Emotion(
        name: "Happy",
        color: Color.yellow,
        pages: [
            ("Journal", "Express your thoughts through journaling"),
            ("Kindness", "Perform an act of kindness for someone else"),
            ("Dance", "Dance to your favorite song")
        ]
    ),
    Emotion(
        name: "Fear",
        color: Color.purple,
        pages: [
            ("SmallGoals", "Set small, achievable goals to build confidence"),
            ("HealthyEating", "Maintain healthy eating habits to support your mental well-being"),
            ("Support", "Reach out for reassurance")
        ]
    ),
    Emotion(
        name: "Surprise",
        color: Color.orange,
        pages: [
            ("breathe", "Take a moment to pause and practice deep breathing"),
            ("Grounding", "Use a grounding exercise to reconnect with the present moment")
        ]
    ),
    Emotion(
        name: "Bad",
        color: Color.brown,
        pages: [
            ("Rest", "Take a rest to recharge your energy"),
            ("Learn", "Learn something new to shift your focus")
        ]
    )
]

// MARK: - Main View
struct MindOnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentEmotion = 0
    @State private var currentPage = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack {
                    // Top bar
                    HStack {
                        if currentPage > 0 {
                            Button {
                                withAnimation { currentPage -= 1 }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                            .padding(.leading, 20)
                        } else {
                            Spacer().frame(width: 44)
                        }

                        Spacer()

                        NavigationLink {
                            ConfettiView()
                                .onAppear{
                                   // hasSeenOnboarding = true
                                }
                        } label: {
                            Text("Done")
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                                .padding(.trailing, 20)
                        }

//                        Button {
//
//                            //
//                        } label: {
//
//                        }
//
                    }
                    .padding(.top, 50)

                    Spacer()

                    // Outer TabView (emotions)
                    TabView(selection: $currentEmotion) {
                        ForEach(0..<emotions.count, id: \.self) { emotionIndex in
                            let emotion = emotions[emotionIndex]

                            VStack {
                                Text(emotion.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(emotion.color)
                                    .padding(.bottom, 20)

                                // Inner TabView (pages for this emotion)
                                TabView(selection: $currentPage) {
                                    ForEach(0..<emotion.pages.count, id: \.self) { pageIndex in
                                        GeometryReader { geo in
                                            VStack {
                                                Image(emotion.pages[pageIndex].image)
                                                    .resizable()
                                                    .renderingMode(.template)
                                                    .foregroundColor(emotion.color)
                                                    .scaledToFit()
                                                    .frame(maxHeight: 250)

                                                Text(emotion.pages[pageIndex].text)
                                                    .font(.system(size: 22, weight: .medium))
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 70)
                                            }
                                            .frame(width: geo.size.width, height: geo.size.height)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
                                        .tag(pageIndex)
                                    }
                                }
                                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                                // Page dots for techniques
                                HStack(spacing: 8) {
                                    ForEach(0..<emotion.pages.count, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentPage ? Color.gray : Color.gray.opacity(0.4))
                                            .frame(width: 8, height: 8)
                                            .onTapGesture { withAnimation { currentPage = index } }
                                    }
                                }
                                .padding(.bottom, 40)
                            }
                            .tag(emotionIndex)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // swipe through emotions
                }
            }
        }
        }
      
}

// MARK: - Preview
struct MindOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        MindOnboardingView()
    }
}
