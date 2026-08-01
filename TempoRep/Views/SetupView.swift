import SwiftUI
import UIKit

struct SetupView: View {
    @Bindable var engine: WorkoutEngine
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showExercisePicker = false
    @State private var showSavePresetAlert = false
    @State private var newPresetName = ""
    @State private var showCustomTempo = false
    private let exerciseDatabase = ExerciseDatabase.shared

    var body: some View {
        ZStack {
            Color.tempoBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    exerciseSection
                    tempoSection
                    presetsSection
                    countersSection
                    unilateralSection
                    estimateSection
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.top, TempoMetrics.setupTopInset)
                .padding(.bottom, Spacing.lg)
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: Spacing.xs) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(TempoFont.rounded(.body, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
                }
                .accessibilityLabel(Text("Settings"))

                Button {
                    showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(TempoFont.rounded(.body, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
                }
                .accessibilityLabel(Text("History"))
            }
            .padding(.top, Spacing.sm)
            .padding(.trailing, Spacing.sm)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(store: engine.history)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(engine: engine)
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView(engine: engine)
        }
        .safeAreaInset(edge: .bottom) { startButton }
    }

    // MARK: - Sections

    private var exerciseSection: some View {
        Button {
            showExercisePicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Exercise")
                        .font(TempoFont.rounded(.caption, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text(verbatim: selectedExercise?.name ?? L("No exercise selected", locale))
                        .font(TempoFont.rounded(.body, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(TempoFont.rounded(.footnote, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.lg)
            .background(Color.tempoSurface, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens the exercise picker"))
    }

    private var selectedExercise: Exercise? {
        exerciseDatabase.exercise(id: engine.config.selectedExerciseID)
    }

    private var tempoSection: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Spacer()
                Button {
                    showCustomTempo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(TempoFont.rounded(.subheadline))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Tempo details"))
                .sheet(isPresented: $showCustomTempo) {
                    CustomTempoView(engine: engine)
                }
            }

            // A standalone row so the 4 digits center on their own — sharing
            // the row with the info button (as this used to) pushed them
            // off-center to make room for it.
            HStack(spacing: Spacing.lg) {
                DigitStepper(label: "tempo.control", accessibilityName: "Eccentric duration",
                             digit: $engine.config.tempoDigits[0])
                DigitStepper(label: "tempo.hold", accessibilityName: "Pause at bottom duration",
                             digit: $engine.config.tempoDigits[1])
                DigitStepper(label: "tempo.drive", accessibilityName: "Concentric duration",
                             digit: $engine.config.tempoDigits[2])
                DigitStepper(label: "tempo.hold", accessibilityName: "Pause at top duration",
                             digit: $engine.config.tempoDigits[3])
            }
            .frame(maxWidth: .infinity)

            if let hint = tempoSuggestionHint {
                Text(verbatim: hint)
                    .font(TempoFont.rounded(.caption2, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Shown only while the digits still match the exercise's suggestion —
    /// disappears the moment the user edits away from it, so it never reads
    /// as a stale claim about what's currently dialed in.
    private var tempoSuggestionHint: String? {
        guard let exercise = selectedExercise,
              let suggested = exercise.suggestedTempo,
              let muscle = exercise.primaryMuscles.first,
              engine.config.tempoDigits == suggested else { return nil }
        return String(format: L("Suggested for %@", locale), muscle.capitalized)
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(verbatim: presetsHeaderText)
                .font(TempoFont.rounded(.caption, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(displayedBuiltInPresets) { preset in
                        PresetChip(displayName: preset.displayName, tempoDigits: preset.tempoDigits,
                                   reversed: preset.reverseDirection, isRecommended: isRecommended(preset)) {
                            apply(preset)
                        }
                    }
                    ForEach(displayedCustomPresets) { preset in
                        PresetChip(displayName: preset.displayName, tempoDigits: preset.tempoDigits,
                                   reversed: preset.reverseDirection, isRecommended: isRecommended(preset)) {
                            apply(preset)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                engine.presets.delete(preset)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    Button {
                        newPresetName = ""
                        showSavePresetAlert = true
                    } label: {
                        Image(systemName: "plus")
                            .font(TempoFont.rounded(.subheadline, weight: .bold))
                            .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
                    }
                    .background(Color.tempoSunken, in: Circle())
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel(Text("Save current settings as a preset"))
                }
            }
        }
        .alert("Save Preset", isPresented: $showSavePresetAlert) {
            TextField("Preset name", text: $newPresetName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                engine.presets.save(name: trimmed, from: engine.config)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    /// Presets with 2-3 different tempos for the same exercise (e.g. one per
    /// training phase) are common — once that exercise is selected, narrow
    /// the row to just those instead of burying them among every preset.
    /// Falls back to showing everything when nothing is selected, or when
    /// the selected exercise has no presets of its own yet.
    private var hasPresetsForSelectedExercise: Bool {
        guard let exerciseID = engine.config.selectedExerciseID else { return false }
        return (WorkoutPreset.builtIn + engine.presets.custom).contains { $0.exerciseID == exerciseID }
    }

    private var displayedBuiltInPresets: [WorkoutPreset] {
        guard hasPresetsForSelectedExercise, let exerciseID = engine.config.selectedExerciseID else {
            return WorkoutPreset.builtIn
        }
        return WorkoutPreset.builtIn.filter { $0.exerciseID == exerciseID }
    }

    private var displayedCustomPresets: [WorkoutPreset] {
        guard hasPresetsForSelectedExercise, let exerciseID = engine.config.selectedExerciseID else {
            return engine.presets.custom
        }
        return engine.presets.custom.filter { $0.exerciseID == exerciseID }
    }

    private var presetsHeaderText: String {
        if hasPresetsForSelectedExercise, let exercise = selectedExercise {
            return String(format: L("Presets for %@", locale), exercise.name)
        }
        return L("Presets", locale)
    }

    private func apply(_ preset: WorkoutPreset) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        preset.apply(to: &engine.config)
        if let exercise = exerciseDatabase.exercise(id: preset.exerciseID) {
            exerciseDatabase.markUsed(exercise)
        }
    }

    /// True when this preset's tempo matches the selected exercise's own
    /// suggested tempo (see `Exercise.suggestedTempo`) — surfaces something
    /// already computed rather than adding a separate curated list.
    private func isRecommended(_ preset: WorkoutPreset) -> Bool {
        guard let suggested = selectedExercise?.suggestedTempo else { return false }
        return preset.tempoDigits == suggested
    }

    private var countersSection: some View {
        VStack(spacing: Spacing.sm) {
            CounterRow(title: "Reps per set", value: $engine.config.repsPerSet, range: 1...30)
            CounterRow(title: "Sets", value: $engine.config.sets, range: 1...10)
            CounterRow(title: "Rest between sets", value: $engine.config.restSeconds, range: 15...300, step: 15, unit: " s")
        }
        .padding(Spacing.xl)
        .background(Color.tempoSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }

    private var unilateralSection: some View {
        VStack(spacing: Spacing.lg) {
            Picker(selection: $engine.config.unilateral) {
                Text("Bilateral").tag(false)
                Text("Unilateral").tag(true)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)
            .sensoryFeedback(.selection, trigger: engine.config.unilateral)

            if engine.config.unilateral {
                CounterRow(title: "Switch time", value: $engine.config.switchSeconds, range: 0...60, step: 5, unit: " s")

                HStack {
                    Text("Starting side")
                        .font(TempoFont.rounded(.body, weight: .medium))
                    Spacer()
                    Picker(selection: $engine.config.startingSide) {
                        ForEach(Side.allCases) { side in
                            Text(verbatim: side.label(locale)).tag(side)
                        }
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.segmented)
                    .frame(width: TempoMetrics.sidePickerWidth)
                    .sensoryFeedback(.selection, trigger: engine.config.startingSide)
                }
            }
        }
        .padding(Spacing.xl)
        .background(Color.tempoSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .animation(TempoAnimation.standard(reduceMotion: reduceMotion), value: engine.config.unilateral)
    }

    private var estimateSection: some View {
        let duration = formatDuration(WorkoutEngine.estimatedDuration(for: engine.config))
        let text = String(format: L("≈ %@ total", locale), duration)
        return Text(verbatim: text)
            .font(TempoFont.rounded(.subheadline, weight: .medium))
            .foregroundStyle(.secondary)
    }

    private var startButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            engine.start()
        } label: {
            Text("START")
                .font(TempoFont.rounded(.title2, weight: .heavy))
                .tracking(TempoTracking.button)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
        }
        .background(Color.accentColor, in: Capsule())
        .foregroundStyle(Color.tempoOnAccent)
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        // A blurred material, not a solid fill — the button floats over
        // the scroll content instead of sitting on an opaque bar.
        .background(.ultraThinMaterial, ignoresSafeAreaEdges: .bottom)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Components

private struct PresetChip: View {
    let displayName: String
    let tempoDigits: [Double]
    var reversed: Bool = false
    var isRecommended: Bool = false
    let action: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                if isRecommended {
                    Text("Recommended")
                        .font(TempoFont.rounded(.caption2, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
                Text(verbatim: displayName)
                    .font(TempoFont.rounded(.caption, weight: .bold))
                    .lineLimit(1)
                Text(verbatim: tempoNotation(tempoDigits, reversed: reversed))
                    .font(TempoFont.rounded(.caption2, weight: .medium).monospacedDigit())
                    .opacity(TempoOpacity.secondaryDetail)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
        }
        .background(Color.tempoSunken, in: Capsule())
        .foregroundStyle(.primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: [
            displayName,
            isRecommended ? L("Recommended", locale) : nil,
            "\(L("Tempo", locale)) \(tempoAccessibilityReading(tempoDigits))",
        ].compactMap { $0 }.joined(separator: ", ")))
    }
}

private struct DigitStepper: View {
    let label: LocalizedStringKey
    let accessibilityName: LocalizedStringKey
    @Binding var digit: Double
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .largeTitle) private var digitSize = TempoMetrics.Display.digit

    var body: some View {
        VStack(spacing: Spacing.md) {
            Button {
                increment()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: TempoMetrics.Icon.large, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: 32)
            }
            .foregroundStyle(Color.accentColor)
            .accessibilityHidden(true)

            Text(verbatim: digit.formatted(.number.locale(locale).precision(.fractionLength(0...1))))
                .font(.system(size: digitSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(TempoScaleFactor.digit)
                .lineLimit(1)
                .frame(width: TempoMetrics.digitBoxWidth, height: TempoMetrics.digitBoxHeight)
                .background(Color.tempoSunken, in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            Button {
                decrement()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: TempoMetrics.Icon.large, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: 32)
            }
            .foregroundStyle(Color.accentColor)
            .accessibilityHidden(true)

            Text(label)
                .font(TempoFont.rounded(.caption2, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .sensoryFeedback(.selection, trigger: digit)
        // A native Stepper presents to VoiceOver as one adjustable element
        // (swipe up/down to change the value) rather than two separately
        // unlabeled +/- buttons — this matches that, since 4 of these sit
        // side by side and "chevron up, button" x4 is meaningless on its own.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityName))
        .accessibilityValue(Text(verbatim: "\(digit)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    // Whole seconds only — tempo prescriptions are written in whole
    // seconds, and half-steps made the digit box read as false precision.
    private func increment() { digit = min(9, digit.rounded(.down) + 1) }
    private func decrement() { digit = max(0, digit.rounded(.up) - 1) }
}

private struct CounterRow: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var unit: String = ""
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text(title)
                .font(TempoFont.rounded(.body, weight: .medium))
            Spacer()
            Button {
                decrement()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: TempoMetrics.Icon.medium, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
                    .background(Color.tempoSunken, in: Circle())
            }
            .foregroundStyle(.primary)
            .accessibilityHidden(true)

            Text(verbatim: "\(value.formatted(.number.locale(locale)))\(unit)")
                .font(TempoFont.rounded(.title3, weight: .bold))
                .monospacedDigit()
                .frame(minWidth: TempoMetrics.counterValueMinWidth)

            Button {
                increment()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: TempoMetrics.Icon.medium, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
                    .background(Color.tempoSunken, in: Circle())
            }
            .foregroundStyle(.primary)
            .accessibilityHidden(true)
        }
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(verbatim: "\(value)\(unit)"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: increment()
            case .decrement: decrement()
            @unknown default: break
            }
        }
    }

    private func increment() { value = min(range.upperBound, value + step) }
    private func decrement() { value = max(range.lowerBound, value - step) }
}

#Preview {
    SetupView(engine: WorkoutEngine())
}
