import SwiftUI
import UIKit

/// Follows the system appearance like every other screen. Legibility
/// across a gym floor comes from scale and contrast — a huge numeral and a
/// full-bleed phase color — rather than from forcing a dark ground.
///
/// This is the only screen that allows landscape — the phone is
/// often propped up on a shelf or in a stand mid-set. Every other screen
/// stays portrait-only; see `OrientationLock`, which this view toggles on
/// appear/disappear.
struct WorkoutView: View {
    let engine: WorkoutEngine
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    /// When the finish screen appeared, for the count-up below.
    @State private var finishedAt: Date?
    @State private var phaseFlashOpacity: Double = 0
    @ScaledMetric(relativeTo: .largeTitle) private var countdownSize = TempoMetrics.Display.countdown
    @ScaledMetric(relativeTo: .title) private var countdownSizeCompact = TempoMetrics.Display.countdownCompact
    @ScaledMetric(relativeTo: .largeTitle) private var phaseTitleSize = TempoMetrics.Display.phaseTitle
    @ScaledMetric(relativeTo: .title) private var finishedTitleSize = TempoMetrics.Display.finishedTitle

    private var isCompactHeight: Bool { verticalSizeClass == .compact }

    /// The phase triad — control / hold / drive. Waiting phases stay
    /// neutral on purpose: resting isn't part of the rep, so giving it a
    /// fourth hue would dilute what the three real phase colors mean.
    /// Signal (the brand accent) deliberately never appears here.
    private var phaseAccentColor: Color {
        switch engine.currentPhase {
        case .eccentric: return .tempoControl
        case .pauseBottom, .pauseTop: return .tempoHold
        case .concentric: return .tempoDrive
        default: return .tempoWaiting
        }
    }

    /// The four phases that make up a rep. These get the pacing track;
    /// get-ready / rest / switch-side are waiting phases and keep the
    /// countdown ring, which is what a plain "time until the next thing"
    /// countdown wants to look like.
    private var isRepPhase: Bool {
        switch engine.currentPhase {
        case .eccentric, .pauseBottom, .concentric, .pauseTop: return true
        default: return false
        }
    }

    /// Swaps the screen's centrepiece. During a rep the full-bleed field
    /// behind everything already carries the progress, so the centre only
    /// needs the seconds remaining and the four tempo values. While
    /// waiting, the countdown ring returns — a ring is the right shape for
    /// "time until the next thing", which is all a rest is.
    @ViewBuilder
    private func centrepiece(ringDiameter: CGFloat, digitSize: CGFloat, compact: Bool) -> some View {
        if isRepPhase {
            VStack(spacing: compact ? Spacing.xs : Spacing.sm) {
                Text(verbatim: countdownText)
                    .font(.system(size: digitSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.tempoPrimaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(TempoScaleFactor.display)
                TempoDigitRow(engine: engine, phaseColor: phaseAccentColor, isCompact: compact)
            }
        } else {
            ring(diameter: ringDiameter, digitSize: digitSize)
        }
    }

    var body: some View {
        ZStack {
            Color.tempoBackground.ignoresSafeArea()
            // The pacing field is a full-bleed layer beneath the readout,
            // not a sibling in the stack — see TempoPacingView's note.
            if isRepPhase, engine.state != .finished {
                TempoPacingView(engine: engine, phaseColor: phaseAccentColor)
            }
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
            .frame(height: TempoMetrics.phaseFlashHeight)
            .opacity(phaseFlashOpacity)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .top)
        }
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
                withAnimation(TempoAnimation.phaseFlashFade) {
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
                    .tracking(TempoTracking.label)
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, Spacing.xs)
            }

            Spacer()

            Text(verbatim: engine.currentPhase.title(locale))
                .font(.system(size: phaseTitleSize, weight: .heavy, design: .rounded))
                .foregroundStyle(engine.state == .paused ? AnyShapeStyle(.secondary) : AnyShapeStyle(phaseAccentColor))
                .minimumScaleFactor(TempoScaleFactor.title)
                .lineLimit(1)
                .padding(.horizontal, Spacing.xl)

            Text(verbatim: subtitle)
                .font(TempoFont.rounded(.title3, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, Spacing.xs)

            centrepiece(ringDiameter: TempoMetrics.ringDiameter,
                        digitSize: countdownSize,
                        compact: false)
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
                        .tracking(TempoTracking.label)
                        .foregroundStyle(Color.accentColor)
                }

                Spacer(minLength: Spacing.md)

                Text(verbatim: engine.currentPhase.title(locale))
                    .font(.system(size: phaseTitleSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(engine.state == .paused ? AnyShapeStyle(.secondary) : AnyShapeStyle(phaseAccentColor))
                    .minimumScaleFactor(TempoScaleFactor.display)
                    .lineLimit(1)

                Text(verbatim: subtitle)
                    .font(TempoFont.rounded(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer(minLength: Spacing.md)

                controls
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            centrepiece(ringDiameter: TempoMetrics.compactRingDiameter,
                        digitSize: countdownSizeCompact,
                        compact: true)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    private func ring(diameter: CGFloat, digitSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.tempoSunken, lineWidth: TempoMetrics.ringLineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, 1 - engine.phaseProgress))
                .stroke(phaseAccentColor, style: StrokeStyle(lineWidth: TempoMetrics.ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(verbatim: countdownText)
                    .font(.system(size: digitSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(TempoScaleFactor.display)
                    .lineLimit(1)
                    .padding(.horizontal, Spacing.xxl)
                if engine.state == .paused {
                    Text("PAUSED")
                        .font(TempoFont.rounded(.body, weight: .bold))
                        .tracking(TempoTracking.label)
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
            .foregroundStyle(Color.tempoOnAccent)

            Button {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                engine.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(TempoFont.rounded(.title3, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
            }
            .background(Color.tempoSunken, in: Capsule())
            .foregroundStyle(Color.tempoPrimaryText)
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
        .onAppear { finishedAt = Date() }
    }

    /// The finish screen's single motion beat: time under tension counts up
    /// from zero. It's the number the whole workout produced, so watching it
    /// accumulate reads as earning it rather than being told it.
    ///
    /// Driven by a `TimelineView` clock rather than `withAnimation`, because
    /// SwiftUI interpolates a view's *layout*, not the string inside a
    /// `Text` — the number has to be recomputed per frame to visibly climb.
    @ViewBuilder
    private var timeUnderTensionStat: some View {
        let total = engine.lastTimeUnderTension
        if reduceMotion {
            StatBlock(value: Self.mmss(total), label: "Time under tension", size: heroStatSize)
        } else {
            TimelineView(.animation) { context in
                let elapsed = finishedAt.map { context.date.timeIntervalSince($0) } ?? 0
                let fraction = min(1, max(0, elapsed / TempoAnimation.countUpDuration))
                // Ease-out so it decelerates onto the final figure instead
                // of stopping dead.
                let eased = 1 - pow(1 - fraction, 3)
                StatBlock(value: Self.mmss(total * eased),
                          label: "Time under tension",
                          size: heroStatSize)
            }
        }
    }

    private var heroStatSize: StatBlock.Size { isCompactHeight ? .large : .hero }

    private var continueButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            engine.stop()
        } label: {
            Text("workout.continueButton")
                .font(TempoFont.rounded(.title2, weight: .heavy))
                .tracking(TempoTracking.button)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
        }
        .background(Color.accentColor, in: Capsule())
        .foregroundStyle(Color.tempoOnAccent)
    }

    private var portraitFinishedView: some View {
        VStack(alignment: .leading, spacing: Spacing.xl) {
            Spacer()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Workout complete")
                    .font(TempoFont.rounded(.caption2, weight: .semibold))
                    .tracking(TempoTracking.label)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.accentColor)
                if let name = engine.lastExerciseName {
                    Text(verbatim: name)
                        .font(TempoFont.rounded(.title, weight: .heavy))
                        .lineLimit(2)
                }
            }

            // Time under tension is what tempo training actually produces,
            // and nothing else in the app reports it — so it's the
            // headline rather than a footnote.
            timeUnderTensionStat

            Divider().overlay(Color.tempoRule)

            HStack(alignment: .top, spacing: Spacing.xl) {
                StatBlock(value: "\(engine.config.sets * engine.config.repsPerSet)", label: "stat.reps")
                StatBlock(value: "\(engine.config.sets)", label: "stat.sets")
                StatBlock(value: engine.config.tempoString, label: "Tempo")
            }

            Spacer()

            continueButton
                .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var landscapeFinishedView: some View {
        HStack(alignment: .center, spacing: Spacing.xxl) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Workout complete")
                    .font(TempoFont.rounded(.caption2, weight: .semibold))
                    .tracking(TempoTracking.label)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.accentColor)
                if let name = engine.lastExerciseName {
                    Text(verbatim: name)
                        .font(TempoFont.rounded(.title2, weight: .heavy))
                        .lineLimit(2)
                }
                timeUnderTensionStat
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top, spacing: Spacing.lg) {
                    StatBlock(value: "\(engine.config.sets * engine.config.repsPerSet)", label: "stat.reps")
                    StatBlock(value: "\(engine.config.sets)", label: "stat.sets")
                    StatBlock(value: engine.config.tempoString, label: "Tempo")
                }
                continueButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
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
