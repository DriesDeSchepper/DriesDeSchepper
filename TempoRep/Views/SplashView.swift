import SwiftUI

/// Shown briefly on launch — the wordmark and app icon motif get their own
/// moment here instead of permanently occupying space on the setup screen,
/// where they were competing with the settings/history buttons. Follows
/// the system appearance like every other screen.
struct SplashView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var wordmarkSize = TempoMetrics.Display.splashWordmark
    @ScaledMetric(relativeTo: .largeTitle) private var digitSize = TempoMetrics.Display.splashDigit

    var body: some View {
        ZStack {
            Color.tempoBackground.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: TempoMetrics.splashLogoLineWidth)
                        .frame(width: TempoMetrics.splashLogoDiameter, height: TempoMetrics.splashLogoDiameter)
                    Text(verbatim: "4")
                        .font(.system(size: digitSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.tempoPrimaryText)
                }

                VStack(spacing: Spacing.xs) {
                    Text(verbatim: "TEMPOREP")
                        .font(.system(size: wordmarkSize, weight: .heavy, design: .rounded))
                        .tracking(TempoTracking.wordmark)
                        .foregroundStyle(Color.tempoPrimaryText)
                    Text("tempo training timer")
                        .font(TempoFont.rounded(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "TempoRep"))
        }
    }
}

#Preview {
    SplashView()
}
