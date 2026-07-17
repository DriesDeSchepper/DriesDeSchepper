import SwiftUI

struct SetupView: View {
    @Bindable var engine: WorkoutEngine
    @Environment(\.locale) private var locale
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showExercisePicker = false
    @State private var showSavePresetAlert = false
    @State private var newPresetName = ""
    @State private var showTempoInfo = false
    private let exerciseDatabase = ExerciseDatabase.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text(verbatim: "TEMPOREP")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .tracking(8)
                        Text("tempo training timer")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    exerciseSection
                    tempoSection
                    presetsSection
                    countersSection
                    unilateralSection
                    estimateSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 4) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("Settings"))

                Button {
                    showHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("History"))
            }
            .padding(.trailing, 8)
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(store: engine.history)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exercise")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(verbatim: selectedExercise?.name ?? L("No exercise selected", locale))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var selectedExercise: Exercise? {
        exerciseDatabase.exercise(id: engine.config.selectedExerciseID)
    }

    private var tempoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                DigitStepper(label: "ECC", digit: $engine.config.tempoDigits[0])
                DigitStepper(label: "PAUSE", digit: $engine.config.tempoDigits[1])
                DigitStepper(label: "CON", digit: $engine.config.tempoDigits[2])
                DigitStepper(label: "PAUSE", digit: $engine.config.tempoDigits[3])

                Button {
                    showTempoInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Tempo details"))
                .popover(isPresented: $showTempoInfo) {
                    tempoInfoPopover
                }
            }
        }
    }

    private var tempoInfoPopover: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Concentric 0 = explosive (timed as 1 s)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Text("Start with")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Picker(selection: $engine.config.startPhase) {
                    Text("Eccentric").tag(StartPhase.eccentric)
                    Text("Concentric").tag(StartPhase.concentric)
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(20)
        .frame(minWidth: 280)
        .presentationCompactAdaptation(.popover)
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WorkoutPreset.builtIn) { preset in
                        PresetChip(displayName: preset.displayName, tempoDigits: preset.tempoDigits) {
                            apply(preset)
                        }
                    }
                    ForEach(engine.presets.custom) { preset in
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
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 44, height: 44)
                    }
                    .background(Color.white.opacity(0.1), in: Circle())
                    .foregroundStyle(Color.accentColor)
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
            }
        }
    }

    private func apply(_ preset: WorkoutPreset) {
        preset.apply(to: &engine.config)
        if let exercise = exerciseDatabase.exercise(id: preset.exerciseID) {
            exerciseDatabase.markUsed(exercise)
        }
    }

    private var countersSection: some View {
        VStack(spacing: 8) {
            CounterRow(title: "Reps per set", value: $engine.config.repsPerSet, range: 1...30)
            CounterRow(title: "Sets", value: $engine.config.sets, range: 1...10)
            CounterRow(title: "Rest between sets", value: $engine.config.restSeconds, range: 15...300, step: 15, unit: " s")
            HStack {
                Text("Voice countdown")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                Spacer()
                Toggle("Voice countdown", isOn: $engine.config.voiceCues)
                    .labelsHidden()
                    .tint(Color.accentColor)
            }
            .padding(.vertical, 4)
        }
        .padding(20)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
    }

    private var unilateralSection: some View {
        VStack(spacing: 16) {
            Picker(selection: $engine.config.unilateral) {
                Text("Bilateral").tag(false)
                Text("Unilateral").tag(true)
            } label: {
                EmptyView()
            }
            .pickerStyle(.segmented)

            if engine.config.unilateral {
                CounterRow(title: "Switch time", value: $engine.config.switchSeconds, range: 0...60, step: 5, unit: " s")

                HStack {
                    Text("Starting side")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
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
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .animation(.easeInOut(duration: 0.2), value: engine.config.unilateral)
    }

    private var estimateSection: some View {
        let duration = formatDuration(WorkoutEngine.estimatedDuration(for: engine.config))
        let text = String(format: L("≈ %@ total", locale), duration)
        return Text(verbatim: text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
    }

    private var startButton: some View {
        Button {
            engine.start()
        } label: {
            Text("START")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .tracking(3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        }
        .background(Color.accentColor, in: Capsule())
        .foregroundStyle(.black)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.black)
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
            VStack(spacing: 2) {
                Text(verbatim: displayName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(verbatim: tempoDigits.map(String.init).joined())
                    .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                    .opacity(0.7)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
        }
        .background(Color.white.opacity(0.1), in: Capsule())
        .foregroundStyle(.white)
    }
}

private struct DigitStepper: View {
    let label: LocalizedStringKey
    @Binding var digit: Int
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 10) {
            Button {
                digit = min(9, digit + 1)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 44, height: 32)
            }
            .foregroundStyle(Color.accentColor)

            Text(verbatim: digit.formatted(.number.locale(locale)))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(width: 56, height: 60)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

            Button {
                digit = max(0, digit - 1)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 44, height: 32)
            }
            .foregroundStyle(Color.accentColor)

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

private struct CounterRow: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var unit: String = ""
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
            Spacer()
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .foregroundStyle(.white)

            Text(verbatim: "\(value.formatted(.number.locale(locale)))\(unit)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 64)

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    SetupView(engine: WorkoutEngine())
        .preferredColorScheme(.dark)
}
