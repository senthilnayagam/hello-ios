import SwiftUI

struct SplashView: View {
    @State private var fadeIn: Bool = false

    var body: some View {
        ZStack {
            // Background matches system background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180, maxHeight: 180)
                    .accessibilityLabel("App Logo")

                Text("made by Senthil in partnership with GPT5")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .opacity(fadeIn ? 1 : 0)
            .scaleEffect(fadeIn ? 1.0 : 0.96)
            .animation(.easeOut(duration: 0.6), value: fadeIn)
        }
        .onAppear {
            fadeIn = true
        }
    }
}

#Preview {
    SplashView()
}
