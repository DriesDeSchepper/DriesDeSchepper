import SwiftUI

struct WorkoutView: View {
    let engine: WorkoutEngine

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if engine.state == .finished {
                finishedView
            } else {
                activeView
            }
        }
    }

    // MARK: - Active workout

    private var activeView: some View {
        VStack(spacing: 0) {
            Text(header)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.top, 24)

            Spacer()

            Text(engine.currentPhase.title)
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .foregroundStyle(engine.state == .paused ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 24)

            Text(subtitle)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            ring
                .padding(.top, 36)

            Spacer()

            controls
                .padding(.bottom, 24)
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.001, 1 - engine.phaseProgress))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(countdownText)
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal, 32)
                if engine.state == .paused {
                    Text("PAUSED")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .frame(width: 300, height: 300)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                if engine.state == .paused {
                    engine.resume()
                } else {
                    engine.pause()
                }
            } label: {
                Label(engine.state == .paused ? "Resume" : "Pause",
                      systemImage: engine.state == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.black)

            Button {
                engine.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .background(Color.white.opacity(0.12), in: Capsule())
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Finished

    private var finishedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("DONE")
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.accentColor)
            Text("\(engine.config.sets) sets · \(engine.config.repsPerSet) reps @ \(engine.config.tempoString)")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                engine.stop()
            } label: {
                Text("FINISH")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .tracking(3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Derived text

    private var header: String {
        switch engine.currentPhase {
        case .getReady:
            return "SET \(engine.currentSet) OF \(engine.config.sets)"
        case .rest:
            return "SET \(engine.currentSet) OF \(engine.config.sets) DONE"
        case .done:
            return ""
        default:
            return "REP \(engine.currentRep)/\(engine.config.repsPerSet) · SET \(engine.currentSet)/\(engine.config.sets)"
        }
    }

    private var subtitle: String {
        if engine.currentPhase == .rest {
            return "up next: set \(engine.currentSet + 1)"
        }
        return engine.currentPhase.subtitle
    }

    private var countdownText: String {
        let remaining = engine.phaseRemaining
        if engine.currentPhase == .rest && remaining >= 60 {
            let seconds = Int(remaining.rounded(.up))
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        }
        return "\(max(1, Int(remaining.rounded(.up))))"
    }
}

#Preview {
    WorkoutView(engine: WorkoutEngine())
        .preferredColorScheme(.dark)
}
