import SwiftUI

/// A glowing dot riding a vertical track, pacing the four phases of a rep:
/// it descends through the eccentric, breathes at the stretched end,
/// drives back up through the concentric, and settles at the contracted
/// end. Beside the track sit the seconds remaining and the four tempo
/// values, with the running one lit and enlarged.
///
/// ## Where the motion comes from
///
/// The dot's **position** is interpolated straight from
/// `WorkoutEngine.phaseProgress`, which the engine derives from wall-clock
/// elapsed time. It is deliberately *not* driven by a `withAnimation`
/// chain or by its own timer:
///
/// - A SwiftUI animation finishes on its own schedule. A spring tuned to
///   feel explosive settles in roughly 0.4s whether the prescribed
///   concentric is 1 second or 4 — the line would hit the top long before
///   the rep should end, contradicting both the countdown and the spoken
///   cue. On a tempo trainer that isn't a polish issue; it's the app
///   misreporting the one thing it exists to teach.
/// - A second timer would be a second clock, free to drift from the
///   engine's. Reading the engine's published progress means the dot
///   cannot disagree with the audio and haptic cues.
///
/// What *is* spring-animated is decoration only — the dot's swell as a
/// phase begins and the active digit's scale-up. Those carry the athletic
/// feel without misstating the pace.
///
/// ## Making an explosive concentric look explosive, honestly
///
/// Rather than fake speed with a spring, the concentric's progress runs
/// through an ease-out whose strength scales with the *prescribed* time
/// (see `concentricEasing`): a `0` or `0.5` digit launches hard and
/// decelerates into the top, while a 3-second concentric stays nearly
/// linear, because at that tempo it genuinely should be controlled.
/// Either way the travel lands exactly when the phase ends.
struct TempoPacingView: View {
    let engine: WorkoutEngine
    /// Already-formatted seconds remaining, passed in so this view and the
    /// countdown ring can't drift apart in how they round.
    let countdownText: String
    /// Point size for the countdown numeral, supplied by the parent's
    /// `@ScaledMetric` so it tracks Dynamic Type with everything else.
    let countdownSize: CGFloat
    /// The running phase's accent, so the track matches the phase title.
    let phaseColor: Color
    var isCompact: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    /// When the current phase began, for the decorative clock below.
    /// Wall-clock rather than a frame counter so the pop decays over a
    /// real duration regardless of render rate.
    @State private var phaseStartedAt = Date()

    private var trackHeight: CGFloat {
        isCompact ? TempoMetrics.Pacing.trackHeightCompact : TempoMetrics.Pacing.trackHeight
    }

    private var dotDiameter: CGFloat {
        isCompact ? TempoMetrics.Pacing.dotDiameterCompact : TempoMetrics.Pacing.dotDiameter
    }

    var body: some View {
        HStack(spacing: isCompact ? Spacing.lg : Spacing.xl) {
            track
            VStack(alignment: .leading, spacing: isCompact ? Spacing.sm : Spacing.lg) {
                Text(verbatim: countdownText)
                    .font(.system(size: countdownSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.tempoOnDark)
                    .lineLimit(1)
                    .minimumScaleFactor(TempoScaleFactor.display)
                digitRow
            }
        }
        .onChange(of: engine.currentPhase) { _, _ in
            phaseStartedAt = Date()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Tempo"))
        .accessibilityValue(Text(verbatim: tempoAccessibilityReading(engine.config.tempoDigits)))
    }

    // MARK: - Track

    private var track: some View {
        ZStack(alignment: .top) {
            Capsule()
                .fill(Color.tempoOnDark.opacity(TempoOpacity.pacingTrack))
                .frame(width: TempoMetrics.Pacing.trackWidth)

            // The stretch already travelled this phase, so the line reads
            // as a path being drawn rather than a dot floating alone.
            Capsule()
                .fill(phaseColor)
                .frame(width: TempoMetrics.Pacing.trackWidth, height: trailHeight)
                .offset(y: trailOffset)
                .opacity(engine.state == .paused ? TempoOpacity.inactiveDigit : 1)

            dot.offset(y: dotCenterOffset)
        }
        .frame(width: dotDiameter, height: trackHeight)
        .accessibilityHidden(true)
    }

    /// The decorative layer runs on its own `TimelineView` clock: the
    /// phase-start swell and the isometric breathing pulse are cosmetic,
    /// so they don't need to be locked to workout timing — and an
    /// independent clock means a long hold breathes at a steady rate
    /// rather than one that stretches with the hold's length.
    private var dot: some View {
        TimelineView(.animation(paused: decorationPaused)) { context in
            let scale = decorativeScale(at: context.date)
            Circle()
                .fill(phaseColor)
                .frame(width: dotDiameter, height: dotDiameter)
                .shadow(color: phaseColor.opacity(glowOpacity),
                        radius: TempoMetrics.Pacing.glowRadius)
                .shadow(color: phaseColor.opacity(glowOpacity * TempoMetrics.Pacing.outerGlowFactor),
                        radius: TempoMetrics.Pacing.glowRadiusOuter)
                .scaleEffect(scale)
        }
    }

    /// The dot's centre, in points from the top of the track.
    private var dotCenterOffset: CGFloat {
        CGFloat(position) * (trackHeight - dotDiameter)
    }

    private var dotCentreFromTop: CGFloat {
        CGFloat(position) * (trackHeight - dotDiameter) + dotDiameter / 2
    }

    private var trailHeight: CGFloat {
        travelsDownward ? dotCentreFromTop : trackHeight - dotCentreFromTop
    }

    private var trailOffset: CGFloat {
        travelsDownward ? 0 : dotCentreFromTop
    }

    // MARK: - Position

    /// `0` is the top of the track, `1` the bottom.
    ///
    /// Computed in anatomical terms first — 0 = contracted, 1 = stretched
    /// — then mirrored when `reverseDirection` is set, because for a lat
    /// pulldown or leg curl the stretched position is the *top* of the
    /// movement rather than the bottom.
    private var position: Double {
        let anatomical: Double
        switch engine.currentPhase {
        case .eccentric:
            anatomical = engine.phaseProgress
        case .pauseBottom:
            anatomical = 1
        case .concentric:
            anatomical = 1 - concentricEasing(engine.phaseProgress)
        case .pauseTop:
            anatomical = 0
        default:
            // Not a rep phase — WorkoutView shows the ring instead.
            anatomical = 0
        }
        return engine.config.reverseDirection ? 1 - anatomical : anatomical
    }

    /// Which end the trail grows from, so it always fills *behind* the dot.
    private var travelsDownward: Bool {
        let downward = engine.currentPhase == .eccentric || engine.currentPhase == .pauseBottom
        return engine.config.reverseDirection ? !downward : downward
    }

    /// Blends linear travel toward a cubic ease-out in proportion to how
    /// explosive the prescribed concentric is. A `0` digit (explosive,
    /// timed as 1s) takes most of the ease-out and visibly launches; a 2s+
    /// concentric takes none and stays linear, because a controlled lift
    /// should look controlled. `f(0) == 0` and `f(1) == 1` either way, so
    /// the dot still lands exactly as the phase ends.
    private func concentricEasing(_ progress: Double) -> Double {
        let threshold = TempoMetrics.Pacing.explosiveThresholdSeconds
        let explosiveness = max(0, min(1, (threshold - engine.config.concentricSeconds) / threshold))
        let easedOut = 1 - pow(1 - progress, 3)
        return progress + explosiveness * (easedOut - progress)
    }

    // MARK: - Decoration

    private var isHolding: Bool {
        engine.currentPhase == .pauseBottom || engine.currentPhase == .pauseTop
    }

    /// Reduce Motion stops the decorative clock outright — position still
    /// updates, since that's information rather than ornament. A paused
    /// workout stops it too, so a phone left mid-set isn't animating.
    private var decorationPaused: Bool {
        reduceMotion || engine.state != .running
    }

    /// Combines a damped swell at the start of each phase with a slow
    /// breathing pulse while holding an isometric position.
    private func decorativeScale(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let since = max(0, date.timeIntervalSince(phaseStartedAt))

        // Damped oscillation: full swell at the instant the phase starts,
        // settling within roughly 0.4s. The brief dip below 1 is what
        // reads as spring rather than a plain fade.
        let decay = exp(-TempoMetrics.Pacing.popDecayRate * since)
        let wobble = cos(2 * .pi * TempoMetrics.Pacing.popWobbleHz * since)
        var scale = 1 + (TempoMetrics.Pacing.dotPopScale - 1) * decay * wobble

        if isHolding {
            let wave = sin(since * 2 * .pi * TempoMetrics.Pacing.holdPulseHz)
            scale += TempoMetrics.Pacing.holdPulseAmplitude * wave
        }
        return max(TempoMetrics.Pacing.minDotScale, scale)
    }

    private var glowOpacity: Double {
        engine.state == .paused ? TempoOpacity.pacingGlow / 2 : TempoOpacity.pacingGlow
    }

    // MARK: - Digits

    private var digitRow: some View {
        HStack(spacing: isCompact ? Spacing.sm : Spacing.md) {
            ForEach(Array(engine.config.tempoDigits.enumerated()), id: \.offset) { index, value in
                let active = index == activeDigitIndex && engine.state == .running
                Text(verbatim: format(value))
                    .font(TempoFont.rounded(isCompact ? .body : .title3, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(active
                                     ? AnyShapeStyle(phaseColor)
                                     : AnyShapeStyle(Color.tempoOnDark.opacity(TempoOpacity.inactiveDigit)))
                    .scaleEffect(active && !reduceMotion ? TempoMetrics.Pacing.activeDigitScale : 1)
                    .shadow(color: active ? phaseColor.opacity(glowOpacity) : .clear,
                            radius: TempoMetrics.Pacing.glowRadiusDigit)
                    // The one place the requested spring belongs: a
                    // decorative scale-up, not the pacing itself.
                    .animation(reduceMotion ? nil : TempoAnimation.athleticPop, value: active)
            }
        }
    }

    /// Index into `tempoDigits` for the phase currently running. The array
    /// is always in canonical order (eccentric, bottom pause, concentric,
    /// top pause) regardless of which phase a rep *starts* with, so this
    /// maps by phase rather than by position in the timeline.
    private var activeDigitIndex: Int? {
        switch engine.currentPhase {
        case .eccentric: return 0
        case .pauseBottom: return 1
        case .concentric: return 2
        case .pauseTop: return 3
        default: return nil
        }
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.locale(locale).precision(.fractionLength(0...1)))
    }
}

#Preview {
    ZStack {
        Color.tempoWorkoutBackground.ignoresSafeArea()
        TempoPacingView(engine: WorkoutEngine(),
                        countdownText: "3",
                        countdownSize: TempoMetrics.Display.countdown,
                        phaseColor: .tempoEccentric)
    }
    .preferredColorScheme(.dark)
}
