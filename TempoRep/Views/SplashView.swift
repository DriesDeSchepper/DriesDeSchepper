import SwiftUI

/// Shown briefly on launch — the wordmark and app icon motif get their own
/// moment here instead of permanently occupying space on the setup screen,
/// where they were competing with the settings/history buttons. Always
/// dark, matching the workout screen — see `WorkoutView`'s doc comment for
/// why those two screens don't follow the system appearance.
struct SplashView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkSize = TempoMetrics.Display.splashWordmark
    @ScaledMetric(relativeTo: .largeTitle) private var digitSize = TempoMetrics.Display.splashDigit

    var body: some View {
        ZStack {
            Color.tempoWorkoutBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 10)
                        .frame(width: 96, height: 96)
                    Text(verbatim: "4")
                        .font(.system(size: digitSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.tempoOnDark)
                }

                VStack(spacing: Spacing.xs) {
                    Text(verbatim: "TEMPOREP")
                        .font(.system(size: wordmarkSize, weight: .heavy, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(Color.tempoOnDark)
                    Text("tempo training timer")
                        .font(TempoFont.rounded(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "TempoRep"))
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SplashView()
}
