import SwiftUI

/// Shown briefly on launch — the wordmark and app icon motif get their own
/// moment here instead of permanently occupying space on the setup screen,
/// where they were competing with the settings/history buttons.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 10)
                        .frame(width: 96, height: 96)
                    Text(verbatim: "4")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text(verbatim: "TEMPOREP")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(.white)
                    Text("tempo training timer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
