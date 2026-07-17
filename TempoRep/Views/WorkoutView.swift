import SwiftUI
import UIKit

struct WorkoutView: View {
    let engine: WorkoutEngine
    @Environment(\.locale) private var locale
    @State private var completionAnimated = false

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
            Text(verbatim: header)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.top, 24)

            if engine.config.unilateral, let side = engine.currentSide {
                Text(verbatim: side.label(locale).uppercased(with: locale))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 6)
            }

            Spacer()

            Text(verbatim: engine.currentPhase.title(locale))
                .font(.system(size: 54, weight: .heavy, design: .rounded))
                .foregroundStyle(engine.state == .paused ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 24)

            Text(verbatim: subtitle)
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
                Text(verbatim: countdownText)
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if engine.state == .paused {
                    engine.resume()
                } else {
                    engine.pause()
                }
            } label: {
                Label(engine.state == .paused ? "Resume" : "workout.pauseButton",
                      systemImage: engine.state == .paused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.black)

            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 130, height: 130)
                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            .scaleEffect(completionAnimated ? 1 : 0.4)
            .opacity(completionAnimated ? 1 : 0)

            Text(verbatim: Phase.done.title(locale))
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.accentColor)

            Text(verbatim: summaryText)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            VStack(spacing: 2) {
                Text(verbatim: Self.mmss(engine.lastTimeUnderTension))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("under tension")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                engine.stop()
            } label: {
                Text("workout.continueButton")
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
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.62)) {
                completionAnimated = true
            }
        }
    }

    private var summaryText: String {
        let sets = engine.config.sets
        let reps = engine.config.repsPerSet
        let setsWord = L(sets == 1 ? "workout.set" : "workout.sets", locale)
        let repsWord = L(reps == 1 ? "workout.rep" : "workout.reps", locale)
        return "\(sets) \(setsWord) · \(reps) \(repsWord) @ \(engine.config.tempoString)"
    }

    /// Under a minute, "0:15" reads ambiguously — spell out the unit
    /// instead. Once there's an actual minutes component, m:ss is
    /// unambiguous on its own.
    private static func mmss(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        if seconds < 60 {
            return "\(seconds)s"
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: - Derived text

    private var header: String {
        switch engine.currentPhase {
        case .getReady:
            return String(format: L("SET %d OF %d", locale), engine.currentSet, engine.config.sets)
        case .rest:
            return String(format: L("SET %d OF %d DONE", locale), engine.currentSet, engine.config.sets)
        case .switchSides:
            return String(format: L("SET %d OF %d", locale), engine.currentSet, engine.config.sets)
        case .done:
            return ""
        default:
            return String(format: L("REP %d/%d · SET %d/%d", locale),
                          engine.currentRep, engine.config.repsPerSet, engine.currentSet, engine.config.sets)
        }
    }

    private var subtitle: String {
        if engine.currentPhase == .rest {
            return String(format: L("up next: set %d", locale), engine.currentSet + 1)
        }
        if engine.currentPhase == .switchSides, let side = engine.currentSide {
            return String(format: L("up next: %@", locale), side.label(locale))
        }
        return engine.currentPhase.subtitle(locale)
    }

    private var countdownText: String {
        let remaining = engine.phaseRemaining
        if (engine.currentPhase == .rest || engine.currentPhase == .switchSides) && remaining >= 60 {
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
