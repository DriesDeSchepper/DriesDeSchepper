import SwiftUI

struct SetupView: View {
    @Bindable var engine: WorkoutEngine

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("TEMPO")
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .tracking(8)
                        Text("tempo training timer")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    tempoSection
                    presetSection
                    countersSection
                    estimateSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .safeAreaInset(edge: .bottom) { startButton }
    }

    // MARK: - Sections

    private var tempoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                DigitStepper(label: "ECC", digit: $engine.config.tempoDigits[0])
                DigitStepper(label: "PAUSE", digit: $engine.config.tempoDigits[1])
                DigitStepper(label: "CON", digit: $engine.config.tempoDigits[2])
                DigitStepper(label: "PAUSE", digit: $engine.config.tempoDigits[3])
            }
            Text("Concentric 0 = explosive (timed as 1 s)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var presetSection: some View {
        HStack(spacing: 12) {
            ForEach(WorkoutConfig.presets, id: \.self) { preset in
                let selected = engine.config.tempoDigits == preset
                Button {
                    engine.config.tempoDigits = preset
                } label: {
                    Text(preset.map(String.init).joined())
                        .font(.system(size: 17, weight: .bold, design: .rounded).monospacedDigit())
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                }
                .background(selected ? Color.accentColor : Color.white.opacity(0.1), in: Capsule())
                .foregroundStyle(selected ? .black : .white)
            }
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

    private var estimateSection: some View {
        Text("≈ \(formatDuration(WorkoutEngine.estimatedDuration(for: engine.config))) total")
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

private struct DigitStepper: View {
    let label: String
    @Binding var digit: Int

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

            Text("\(digit)")
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
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var unit: String = ""

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

            Text("\(value)\(unit)")
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
