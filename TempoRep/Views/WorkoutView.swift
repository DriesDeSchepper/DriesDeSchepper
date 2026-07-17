import SwiftUI
import UIKit

/// Deliberately always dark, regardless of the system appearance — unlike
/// every other screen in the app. The countdown display is designed to be
/// read at a glance across a gym floor, and a bright white flash mid-set
/// (if the workout screen simply inherited light mode) would be actively
/// unpleasant and would blow out the display's contrast. See
/// `.preferredColorScheme(.dark)` below.
struct WorkoutView: View {
    let engine: WorkoutEngine
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var completionAnimated = false
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize = TempoMetrics.Display.countdown
    @ScaledMetric(relativeTo: .largeTitle) private var phaseTitleSize = TempoMetrics.Display.phaseTitle
    @ScaledMetric(relativeTo: .title) private var finishedTitleSize = TempoMetrics.Display.finishedTitle

    var body: some View {
        ZStack {
            Color.tempoWorkoutBackground.ignoresSafeArea()
            if engine.state == .finished {
                finishedView
            } else {
                activeView
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: engine.currentPhase) { _, newPhase in
            // VoiceOver users need phase changes even with the optional
            // spoken voice cues turned off — this is a separate,
            // accessibility-only announcement, not the app's own TTS.
            guard engine.state == .running || engine.state == .paused else { return }
            UIAccessibility.post(notification: .announcement, argument: newPhase.title(locale))
        }
        .onChange(of: engine.state) { _, newState in
            if newState == .finished {
                UIAccessibility.post(notification: .screenChanged, argument: Phase.done.title(locale))
            }
        }
    }

    // MARK: - Active workout

    private var activeView: some View {
        VStack(spacing: 0) {
            Text(verbatim: header)
                .font(TempoFont.rounded(.title3, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.xl)

            if engine.config.unilateral, let side = engine.currentSide {
                Text(verbatim: side.label(locale).uppercased(with: locale))
                    .font(TempoFont.rounded(.footnote, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, Spacing.xs)
            }

            Spacer()

            Text(verbatim: engine.currentPhase.title(locale))
                .font(.system(size: phaseTitleSize, weight: .heavy, design: .rounded))
                .foregroundStyle(engine.state == .paused ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.tempoOnDark))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xl)

            Text(verbatim: subtitle)
                .font(TempoFont.rounded(.title3, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.xs)

            ring
                .padding(.top, Spacing.xxl)

            Spacer()

            controls
                .padding(.bottom, Spacing.xl)
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Color.tempoOnDarkSurface, lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.001, 1 - engine.phaseProgress))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(verbatim: countdownText)
                    .font(.system(size: countdownSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.xxl)
                if engine.state == .paused {
                    Text("PAUSED")
                        .font(TempoFont.rounded(.body, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .frame(width: 300, height: 300)
        .accessibilityElement(children: .ignore)
        // Reuses the existing "PAUSED" catalog key (already shown visually
        // above) rather than adding a new "Paused" one — the two would
        // collide as the same generated Swift symbol (case-insensitive).
        .accessibilityLabel(Text(engine.state == .paused ? "PAUSED" : "Time remaining in this phase"))
        .accessibilityValue(Text(verbatim: countdownText))
    }

    private var controls: some View {
        HStack(spacing: Spacing.lg) {
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
                    .font(TempoFont.rounded(.title3, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            }
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.black)

            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                engine.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(TempoFont.rounded(.title3, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            }
            .background(Color.tempoOnDarkSurfaceRaised, in: Capsule())
            .foregroundStyle(Color.tempoOnDark)
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Finished

    private var finishedView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 130, height: 130)
                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            // Reduce Motion: skip the scale entirely, keep only the fade —
            // a crossfade instead of a "pop in" motion.
            .scaleEffect(reduceMotion ? 1 : (completionAnimated ? 1 : 0.4))
            .opacity(completionAnimated ? 1 : 0)
            .accessibilityHidden(true)

            Text(verbatim: Phase.done.title(locale))
                .font(.system(size: finishedTitleSize, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.accentColor)

            Text(verbatim: summaryText)
                .font(TempoFont.rounded(.body, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.xs) {
                Text(verbatim: Self.mmss(engine.lastTimeUnderTension))
                    .font(TempoFont.rounded(.title, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(Color.tempoOnDark)
                Text("under tension")
                    .font(TempoFont.rounded(.caption, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.xs)
            .accessibilityElement(children: .combine)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                engine.stop()
            } label: {
                Text("workout.continueButton")
                    .font(TempoFont.rounded(.title2, weight: .heavy))
                    .tracking(3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xl)
            }
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.black)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            withAnimation(TempoAnimation.celebration(reduceMotion: reduceMotion)) {
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
}
