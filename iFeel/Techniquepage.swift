import SwiftUI

struct TechView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages = [
        "Focus on your body and thoughts",
        "Take deep breaths and relax",
        "Clear your mind and meditate",
        "Journal your thoughts and feelings"
    ]

    var body: some View {
        ZStack {
            Color(red: 0.90, green: 1.0, blue: 0.90)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    if currentPage == pages.count - 1 {
                        Button {
                            hasSeenOnboarding = true
                        } label: {
                            Text("Done")
                                .fontWeight(.medium)
                                .foregroundColor(.black)
                        }
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 50)

                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        GeometryReader { geometry in
                            VStack {
                                Spacer()
                                Image("Icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: geometry.size.width * 0.9,
                                           maxHeight: 250)
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 50)

                                Text(pages[index])
                                    .font(.system(size: 22, weight: .medium))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 70)

                                Spacer()
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) 
                #endif

               
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.gray : Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation { currentPage = index }
                            }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    TechView()
}
