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
    @State private var showTempoInfo = false
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
                    showTempoInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(TempoFont.rounded(.subheadline))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Tempo details"))
                .popover(isPresented: $showTempoInfo) {
                    tempoInfoPopover
                }
            }

            // A standalone row so the 4 digits center on their own — sharing
            // the row with the info button (as this used to) pushed them
            // off-center to make room for it.
            HStack(spacing: Spacing.lg) {
                DigitStepper(label: "ECC", accessibilityName: "Eccentric duration",
                             digit: $engine.config.tempoDigits[0])
                DigitStepper(label: "PAUSE", accessibilityName: "Pause at bottom duration",
                             digit: $engine.config.tempoDigits[1])
                DigitStepper(label: "CON", accessibilityName: "Concentric duration",
                             digit: $engine.config.tempoDigits[2])
                DigitStepper(label: "PAUSE", accessibilityName: "Pause at top duration",
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

    private var tempoInfoPopover: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Text("Concentric 0 = explosive (timed as 1 s)")
                .font(TempoFont.rounded(.subheadline))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Start with")
                    .font(TempoFont.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
                Picker(selection: $engine.config.startPhase) {
                    Text("Eccentric").tag(StartPhase.eccentric)
                    Text("Concentric").tag(StartPhase.concentric)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
                .sensoryFeedback(.selection, trigger: engine.config.startPhase)
            }
        }
        .padding(Spacing.xl)
        .frame(minWidth: 280)
        .presentationCompactAdaptation(.popover)
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(verbatim: presetsHeaderText)
                .font(TempoFont.rounded(.caption, weight: .semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(displayedBuiltInPresets) { preset in
                        PresetChip(displayName: preset.displayName, tempoDigits: preset.tempoDigits) {
                            apply(preset)
                        }
                    }
                    ForEach(displayedCustomPresets) { preset in
                        PresetChip(displayName: preset.displayName, tempoDigits: preset.tempoDigits) {
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
                    .background(Color.tempoSurfaceRaised, in: Circle())
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
                    .frame(width: 160)
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
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
        }
        .background(Color.accentColor, in: Capsule())
        // Fixed black, not `.primaryText` — checked against both of
        // AccentColor's light/dark variants (see Assets.xcassets), black
        // clears WCAG AA contrast on either one.
        .foregroundStyle(.black)
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
    let tempoDigits: [Int]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text(verbatim: displayName)
                    .font(TempoFont.rounded(.caption, weight: .bold))
                    .lineLimit(1)
                Text(verbatim: tempoDigits.map(String.init).joined())
                    .font(TempoFont.rounded(.caption2, weight: .medium).monospacedDigit())
                    .opacity(0.7)
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
        }
        .background(Color.tempoSurfaceRaised, in: Capsule())
        .foregroundStyle(.primary)
    }
}

private struct DigitStepper: View {
    let label: LocalizedStringKey
    let accessibilityName: LocalizedStringKey
    @Binding var digit: Int
    @Environment(\.locale) private var locale
    @ScaledMetric(relativeTo: .largeTitle) private var digitSize = TempoMetrics.Display.digit

    var body: some View {
        VStack(spacing: Spacing.md) {
            Button {
                increment()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: 32)
            }
            .foregroundStyle(Color.accentColor)
            .accessibilityHidden(true)

            Text(verbatim: digit.formatted(.number.locale(locale)))
                .font(.system(size: digitSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(width: 56, height: 60)
                .background(Color.tempoSurfaceRaised, in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            Button {
                decrement()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
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

    private func increment() { digit = min(9, digit + 1) }
    private func decrement() { digit = max(0, digit - 1) }
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
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
                    .background(Color.tempoSurfaceRaised, in: Circle())
            }
            .foregroundStyle(.primary)
            .accessibilityHidden(true)

            Text(verbatim: "\(value.formatted(.number.locale(locale)))\(unit)")
                .font(TempoFont.rounded(.title3, weight: .bold))
                .monospacedDigit()
                .frame(minWidth: 64)

            Button {
                increment()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
                    .background(Color.tempoSurfaceRaised, in: Circle())
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
