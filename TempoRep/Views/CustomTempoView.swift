import SwiftUI

/// A spacious, one-row-per-phase tempo editor — the compact 4-column
/// stepper on the setup screen is fast to nudge, but there's no room
/// there to explain what each phase means or to comfortably show
/// half-second values. Reached via the info button next to those compact
/// steppers; this is where "Start with" and "Reverse Direction" live too,
/// consolidating every tempo-shape setting in one place.
struct CustomTempoView: View {
    @Bindable var engine: WorkoutEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhaseRow(title: "tempo.control", accessibilityTitle: "Eccentric duration",
                             description: "Lower the weight and lengthen the muscle",
                             value: $engine.config.tempoDigits[0])
                    PhaseRow(title: "Bottom Pause", accessibilityTitle: "Pause at bottom duration",
                             description: "Hold at the bottom",
                             value: $engine.config.tempoDigits[1])
                    PhaseRow(title: "tempo.drive", accessibilityTitle: "Concentric duration",
                             description: "Lift the weight and contract the muscle",
                             value: $engine.config.tempoDigits[2])
                    PhaseRow(title: "Top Pause", accessibilityTitle: "Pause at top duration",
                             description: "Hold at the top",
                             value: $engine.config.tempoDigits[3])
                } header: {
                    Text("Seconds per phase")
                } footer: {
                    Text("Concentric 0 = explosive (timed as 1 s)")
                }

                Section {
                    Picker(selection: $engine.config.startPhase) {
                        Text("Eccentric").tag(StartPhase.eccentric)
                        Text("Concentric").tag(StartPhase.concentric)
                    } label: {
                        Text("Start with")
                    }
                    .sensoryFeedback(.selection, trigger: engine.config.startPhase)

                    Toggle(isOn: $engine.config.reverseDirection) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Reverse Direction")
                            Text("Swap which direction the contractions move (e.g. lat pulldown)")
                                .font(TempoFont.rounded(.caption))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color.accentColor)
                    .sensoryFeedback(.selection, trigger: engine.config.reverseDirection)
                } header: {
                    Text("Rep direction")
                }
            }
            .navigationTitle("Custom Tempo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton { dismiss() }
                }
            }
        }
        .tint(Color.accentColor)
    }
}

private struct PhaseRow: View {
    let title: LocalizedStringKey
    let accessibilityTitle: LocalizedStringKey
    let description: LocalizedStringKey
    @Binding var value: Double
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(TempoFont.rounded(.body, weight: .semibold))
                Text(description)
                    .font(TempoFont.rounded(.caption))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            stepper
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityTitle))
        .accessibilityValue(Text(verbatim: formattedValue))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    private var formattedValue: String {
        value.formatted(.number.locale(locale).precision(.fractionLength(0...1)))
    }

    /// One pill with both buttons and the value, rather than three
    /// separate controls — matches the compact `DigitStepper`/`CounterRow`
    /// steppers elsewhere, just wider to comfortably fit "9.5".
    private var stepper: some View {
        HStack(spacing: 0) {
            Button {
                decrement()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: TempoMetrics.Icon.small, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
            }
            Text(verbatim: formattedValue)
                .font(TempoFont.rounded(.body, weight: .bold))
                .monospacedDigit()
                .frame(width: TempoMetrics.stepperValueWidth)
            Button {
                increment()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: TempoMetrics.Icon.small, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
            }
        }
        .foregroundStyle(.primary)
        .background(Color.tempoSunken, in: RoundedRectangle(cornerRadius: CornerRadius.sm))
        .accessibilityHidden(true)
    }

    // Whole seconds only — see the matching note in SetupView.
    private func increment() { value = min(9, value.rounded(.down) + 1) }
    private func decrement() { value = max(0, value.rounded(.up) - 1) }
}

#Preview {
    CustomTempoView(engine: WorkoutEngine())
}
