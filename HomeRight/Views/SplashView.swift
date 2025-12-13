import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
                Text("HomeRight")
                    .font(.largeTitle.weight(.bold))
                Text("Prepping your upkeep plan…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SplashView()
}
