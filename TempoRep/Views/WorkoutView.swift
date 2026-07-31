import SwiftUI
import UIKit

/// Deliberately always dark, regardless of the system appearance — unlike
/// every other screen in the app. The countdown display is designed to be
/// read at a glance across a gym floor, and a bright white flash mid-set
/// (if the workout screen simply inherited light mode) would be actively
/// unpleasant and would blow out the display's contrast. See
/// `.preferredColorScheme(.dark)` below.
///
/// This is also the only screen that allows landscape — the phone is
/// often propped up on a shelf or in a stand mid-set. Every other screen
/// stays portrait-only; see `OrientationLock`, which this view toggles on
/// appear/disappear.
struct WorkoutView: View {
    let engine: WorkoutEngine
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var completionAnimated = false
    @State private var phaseFlashOpacity: Double = 0
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize = TempoMetrics.Display.countdown
    @ScaledMetric(relativeTo: .title) private var countdownSizeCompact = TempoMetrics.Display.countdownCompact
    @ScaledMetric(relativeTo: .largeTitle) private var phaseTitleSize = TempoMetrics.Display.phaseTitle
    @ScaledMetric(relativeTo: .title) private var finishedTitleSize = TempoMetrics.Display.finishedTitle

    private var isCompactHeight: Bool { verticalSizeClass == .compact }

    /// Eccentric (lowering) and get-ready each get their own deliberate
    /// color; every other phase — concentric included — uses the regular
    /// accent. Applied to the phase title and the ring's progress arc; the
    /// countdown digit itself stays neutral white regardless of phase.
    private var phaseAccentColor: Color {
        switch engine.currentPhase {
        case .eccentric: return .tempoEccentric
        case .getReady: return .tempoGetReady
        default: return .accentColor
        }
    }

    var body: some View {
        ZStack {
            Color.tempoWorkoutBackground.ignoresSafeArea()
            if engine.state == .finished {
                finishedView
            } else {
                activeView
            }
        }
        .overlay(alignment: .top) {
            // A brief phase-colored flash at the top edge on every phase
            // change — a "reacting to you" touch alongside the phase
            // color and countdown. Purely decorative, so it's the one
            // thing here that's skipped outright under Reduce Motion
            // rather than given a plainer substitute.
            LinearGradient(
                colors: [phaseAccentColor.opacity(0), phaseAccentColor, phaseAccentColor.opacity(0)],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 3)
            .opacity(phaseFlashOpacity)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .top)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            OrientationLock.mask = .all
            OrientationLock.apply()
        }
        .onDisappear {
            OrientationLock.mask = .portrait
            OrientationLock.apply()
        }
        .onChange(of: engine.currentPhase) { _, newPhase in
            // VoiceOver users need phase changes even with the optional
            // spoken voice cues turned off — this is a separate,
            // accessibility-only announcement, not the app's own TTS.
            guard engine.state == .running || engine.state == .paused else { return }
            UIAccessibility.post(notification: .announcement, argument: newPhase.title(locale))
            if !reduceMotion {
                phaseFlashOpacity = 1
                withAnimation(.easeOut(duration: 0.6)) {
                    phaseFlashOpacity = 0
                }
            }
        }
        .onChange(of: engine.state) { _, newState in
            if newState == .finished {
                UIAccessibility.post(notification: .screenChanged, argument: Phase.done.title(locale))
            }
        }
    }

    // MARK: - Active workout

    private var activeView: some View {
        Group {
            if isCompactHeight {
                landscapeActiveView
            } else {
                portraitActiveView
            }
        }
    }

    private var portraitActiveView: some View {
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
                .foregroundStyle(engine.state == .paused ? AnyShapeStyle(.secondary) : AnyShapeStyle(phaseAccentColor))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xl)

            Text(verbatim: subtitle)
                .font(TempoFont.rounded(.title3, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.xs)

            ring(diameter: 300, digitSize: countdownSize)
                .padding(.top, Spacing.xxl)

            Spacer()

            controls
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
        }
    }

    /// Text on the left, ring on the right — landscape's constraint is
    /// height, not width, so a vertical stack of everything (portrait's
    /// layout) would overflow or force scrolling on shorter iPhones.
    private var landscapeActiveView: some View {
        HStack(spacing: Spacing.xxl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(verbatim: header)
                    .font(TempoFont.rounded(.subheadline, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                if engine.config.unilateral, let side = engine.currentSide {
                    Text(verbatim: side.label(locale).uppercased(with: locale))
                        .font(TempoFont.rounded(.footnote, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color.accentColor)
                }

                Spacer(minLength: Spacing.md)

                Text(verbatim: engine.currentPhase.title(locale))
                    .font(.system(size: phaseTitleSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(engine.state == .paused ? AnyShapeStyle(.secondary) : AnyShapeStyle(phaseAccentColor))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)

                Text(verbatim: subtitle)
                    .font(TempoFont.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer(minLength: Spacing.md)

                controls
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ring(diameter: TempoMetrics.compactRingDiameter, digitSize: countdownSizeCompact)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    private func ring(diameter: CGFloat, digitSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.tempoOnDarkSurface, lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.001, 1 - engine.phaseProgress))
                .stroke(phaseAccentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(verbatim: countdownText)
                    .font(.system(size: digitSize, weight: .bold, design: .rounded))
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
        .frame(width: diameter, height: diameter)
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
    }

    // MARK: - Finished

    private var finishedView: some View {
        Group {
            if isCompactHeight {
                landscapeFinishedView
            } else {
                portraitFinishedView
            }
        }
        .onAppear {
            withAnimation(TempoAnimation.celebration(reduceMotion: reduceMotion)) {
                completionAnimated = true
            }
        }
    }

    private var checkmarkBadge: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 130, height: 130)
            Image(systemName: "checkmark")
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(Color.accentColor)
        }
        // Reduce Motion: skip the scale entirely, keep only the fade — a
        // crossfade instead of a "pop in" motion.
        .scaleEffect(reduceMotion ? 1 : (completionAnimated ? 1 : 0.4))
        .opacity(completionAnimated ? 1 : 0)
        .accessibilityHidden(true)
    }

    private var timeUnderTensionBlock: some View {
        VStack(spacing: Spacing.xs) {
            Text(verbatim: Self.mmss(engine.lastTimeUnderTension))
                .font(TempoFont.rounded(.title, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color.tempoOnDark)
            Text("under tension")
                .font(TempoFont.rounded(.caption, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var continueButton: some View {
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
    }

    private var portraitFinishedView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            checkmarkBadge

            Text(verbatim: Phase.done.title(locale))
                .font(.system(size: finishedTitleSize, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.accentColor)

            Text(verbatim: summaryText)
                .font(TempoFont.rounded(.body, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text(verbatim: accessibleSummaryText))

            timeUnderTensionBlock
                .padding(.top, Spacing.xs)

            Spacer()

            continueButton
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xl)
        }
    }

    private var landscapeFinishedView: some View {
        HStack(spacing: Spacing.xxl) {
            VStack(spacing: Spacing.sm) {
                checkmarkBadge
                    .scaleEffect(0.7) // fits a compact-height screen alongside the summary column
                Text(verbatim: Phase.done.title(locale))
                    .font(.system(size: finishedTitleSize, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(Color.accentColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.md) {
                Text(verbatim: summaryText)
                    .font(TempoFont.rounded(.body, weight: .medium))
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text(verbatim: accessibleSummaryText))
                timeUnderTensionBlock
                continueButton
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    private var summaryText: String {
        let sets = engine.config.sets
        let reps = engine.config.repsPerSet
        let setsWord = L(sets == 1 ? "workout.set" : "workout.sets", locale)
        let repsWord = L(reps == 1 ? "workout.rep" : "workout.reps", locale)
        return "\(sets) \(setsWord) · \(reps) \(repsWord) @ \(engine.config.tempoString)"
    }

    /// `summaryText` with a plain dash-separated tempo reading instead of
    /// the arrow/dot notation, which VoiceOver doesn't reliably speak.
    private var accessibleSummaryText: String {
        let sets = engine.config.sets
        let reps = engine.config.repsPerSet
        let setsWord = L(sets == 1 ? "workout.set" : "workout.sets", locale)
        let repsWord = L(reps == 1 ? "workout.rep" : "workout.reps", locale)
        let tempo = tempoAccessibilityReading(engine.config.tempoDigits)
        return "\(sets) \(setsWord) · \(reps) \(repsWord) @ \(tempo)"
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
