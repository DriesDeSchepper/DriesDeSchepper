import SwiftUI

/// A single figure with a micro-caps label beneath it — the app's core
/// readout unit, used on the setup screen, the finish screen and in the
/// history feed.
///
/// The pairing (large tabular numeral, small tracked uppercase label) is
/// what makes a screenful of settings scan as data rather than as a form.
/// `tabular` keeps digits from jittering when a value ticks.
struct StatBlock: View {
    let value: String
    let label: LocalizedStringKey
    var size: Size = .regular
    var tint: Color?
    var alignment: HorizontalAlignment = .leading

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize = TempoMetrics.Display.statHero

    enum Size {
        case regular, large, hero
    }

    var body: some View {
        VStack(alignment: alignment, spacing: Spacing.xs) {
            Text(verbatim: value)
                .font(valueFont)
                .monospacedDigit()
                .foregroundStyle(tint ?? Color.tempoPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(TempoScaleFactor.digit)
            Text(label)
                .font(TempoFont.rounded(.caption2, weight: .semibold))
                .tracking(TempoTracking.label)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private var valueFont: Font {
        switch size {
        case .regular: return TempoFont.rounded(.title2, weight: .bold)
        case .large: return TempoFont.rounded(.largeTitle, weight: .heavy)
        // Bigger than any standard text style, so it scales via
        // @ScaledMetric rather than mapping to one — same approach as the
        // workout countdown.
        case .hero: return .system(size: heroSize, weight: .heavy, design: .rounded)
        }
    }
}

/// The four tempo values drawn as proportional bars, coloured by phase.
///
/// Turns a tempo from a string you have to parse into a shape you
/// recognise: a slow eccentric with an explosive drive looks visibly
/// different from an even 3-0-3-0, so two sessions of the same lift become
/// comparable at a glance in the history feed.
struct TempoShape: View {
    let digits: [Double]
    var height: CGFloat = TempoMetrics.tempoShapeHeight

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            ForEach(Array(digits.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: TempoMetrics.tempoShapeBarRadius)
                    .fill(Color.tempoPhase(at: index))
                    .frame(height: barHeight(for: value))
            }
        }
        .frame(height: height, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Tempo"))
        .accessibilityValue(Text(verbatim: tempoAccessibilityReading(digits)))
    }

    /// Scaled against the longest phase in *this* tempo, so the shape reads
    /// as proportion rather than absolute seconds. A zero still draws a
    /// sliver, since "no pause" is information worth seeing.
    private func barHeight(for value: Double) -> CGFloat {
        let peak = max(digits.max() ?? 1, 1)
        let floor = TempoMetrics.tempoShapeMinBar
        return floor + (height - floor) * CGFloat(value / peak)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.xl) {
        HStack(spacing: Spacing.xl) {
            StatBlock(value: "8", label: "stat.reps")
            StatBlock(value: "3", label: "stat.sets")
            StatBlock(value: "90s", label: "stat.rest")
        }
        StatBlock(value: "4:48", label: "Time under tension", size: .hero)
        TempoShape(digits: [3, 1, 1, 0])
    }
    .padding()
}
