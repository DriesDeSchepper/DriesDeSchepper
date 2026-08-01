import SwiftUI

/// The rep, rendered as the whole screen: a bright edge line tracks the
/// lifted weight's position and the phase colour floods the area beneath
/// it, so driving up floods the screen and controlling down drains it. At a
/// glance from across a gym you read the colour and the fill level long
/// before you could read any text.
///
/// This is a **background layer**, not a sibling in `WorkoutView`'s stack.
/// A `GeometryReader` has no intrinsic size, so placing one between the
/// phase title and the controls would let it fight the surrounding spacers
/// for height. As a full-bleed background it simply fills, and the readout
/// composes on top in the normal layout.
///
/// ## Where the motion comes from
///
/// The edge's **position** is interpolated straight from
/// `WorkoutEngine.phaseProgress`, which the engine derives from wall-clock
/// elapsed time. It is deliberately *not* driven by a `withAnimation`
/// chain or by its own timer:
///
/// - A SwiftUI animation finishes on its own schedule. A spring tuned to
///   feel explosive settles in roughly 0.4s whether the prescribed drive
///   is 1 second or 4 — the fill would reach the top long before the rep
///   should end, contradicting both the countdown and the spoken cue. On a
///   tempo trainer that isn't a polish issue; it's the app misreporting
///   the one thing it exists to teach.
/// - A second timer would be a second clock, free to drift from the
///   engine's. Reading the engine's published progress means the fill
///   cannot disagree with the audio and haptic cues.
///
/// What *is* spring-animated is decoration only — the edge's swell as a
/// phase begins, and (in `TempoDigitRow`) the active value's scale-up.
///
/// ## Making an explosive drive look explosive, honestly
///
/// Rather than fake speed with a spring, the drive's progress runs through
/// an ease-out whose strength scales with the *prescribed* time (see
/// `driveEasing`): a 1-second drive launches hard and decelerates into the
/// top, while a 3-second drive stays nearly linear, because at that tempo
/// it genuinely should be controlled. Either way the fill lands exactly
/// when the phase ends.
///
/// ## Legibility over a moving ground
///
/// The field is a low-alpha gradient rather than a solid fill, so the
/// numerals on top keep their contrast at every fill level. That's what
/// makes a full-bleed colour field safe on a light ground — a solid fill
/// would strand text mid-sweep.
struct TempoPacingView: View {
    let engine: WorkoutEngine
    /// The running phase's colour, from the triad in `WorkoutView`.
    let phaseColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// When the current phase began, for the decorative clock below.
    /// Wall-clock rather than a frame counter, so the swell decays over a
    /// real duration regardless of render rate.
    @State private var phaseStartedAt = Date()

    var body: some View {
        GeometryReader { geo in
            let fill = max(0, (1 - position) * geo.size.height)
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [phaseColor.opacity(TempoOpacity.fieldBase),
                             phaseColor.opacity(TempoOpacity.fieldTop)],
                    startPoint: .bottom, endPoint: .top
                )
                .frame(height: fill)

                TimelineView(.animation(paused: decorationPaused)) { context in
                    Rectangle()
                        .fill(phaseColor)
                        .frame(height: TempoMetrics.Pacing.edgeThickness)
                        .shadow(color: phaseColor.opacity(glowOpacity),
                                radius: TempoMetrics.Pacing.glowRadius)
                        .shadow(color: phaseColor.opacity(glowOpacity * TempoMetrics.Pacing.outerGlowFactor),
                                radius: TempoMetrics.Pacing.glowRadiusOuter)
                        .scaleEffect(y: decorativeScale(at: context.date))
                        .offset(y: -fill)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: engine.currentPhase) { _, _ in
            phaseStartedAt = Date()
        }
    }

    // MARK: - Position

    /// `0` is the top of the travel (contracted), `1` the bottom
    /// (stretched). The field fills *below* this point, so the screen
    /// floods as the lifter drives.
    ///
    /// Computed in anatomical terms first, then mirrored when
    /// `reverseDirection` is set — for a lat pulldown or leg curl the
    /// stretched position is the top of the movement, not the bottom.
    private var position: Double {
        let anatomical: Double
        switch engine.currentPhase {
        case .eccentric:
            anatomical = engine.phaseProgress
        case .pauseBottom:
            anatomical = 1
        case .concentric:
            anatomical = 1 - driveEasing(engine.phaseProgress)
        case .pauseTop:
            anatomical = 0
        default:
            // Not a rep phase — WorkoutView doesn't show the field at all.
            anatomical = 0
        }
        return engine.config.reverseDirection ? 1 - anatomical : anatomical
    }

    /// Blends linear travel toward a cubic ease-out in proportion to how
    /// explosive the prescribed drive is. A 1-second drive takes most of
    /// the ease-out and visibly launches; a 2s+ drive takes none and stays
    /// linear, because a controlled lift should look controlled. `f(0)==0`
    /// and `f(1)==1` either way, so the fill still lands exactly as the
    /// phase ends.
    private func driveEasing(_ progress: Double) -> Double {
        let threshold = TempoMetrics.Pacing.explosiveThresholdSeconds
        let explosiveness = max(0, min(1, (threshold - engine.config.concentricSeconds) / threshold))
        let easedOut = 1 - pow(1 - progress, 3)
        return progress + explosiveness * (easedOut - progress)
    }

    // MARK: - Decoration

    private var isHolding: Bool {
        engine.currentPhase == .pauseBottom || engine.currentPhase == .pauseTop
    }

    /// Reduce Motion stops the decorative clock outright — the fill still
    /// tracks, since that's information rather than ornament. A paused
    /// workout stops it too, so a phone left mid-set isn't animating.
    private var decorationPaused: Bool {
        reduceMotion || engine.state != .running
    }

    /// A damped swell on the edge as each phase begins, plus a slow
    /// breathing pulse while holding an isometric position. Scales the
    /// edge's thickness only, so it never shifts the fill level.
    private func decorativeScale(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let since = max(0, date.timeIntervalSince(phaseStartedAt))

        let decay = exp(-TempoMetrics.Pacing.popDecayRate * since)
        let wobble = cos(2 * .pi * TempoMetrics.Pacing.popWobbleHz * since)
        var scale = 1 + (TempoMetrics.Pacing.edgeSwellScale - 1) * decay * wobble

        if isHolding {
            let wave = sin(since * 2 * .pi * TempoMetrics.Pacing.holdPulseHz)
            scale += TempoMetrics.Pacing.holdPulseAmplitude * wave
        }
        return max(TempoMetrics.Pacing.minEdgeScale, scale)
    }

    private var glowOpacity: Double {
        engine.state == .paused ? TempoOpacity.pacingGlow / 2 : TempoOpacity.pacingGlow
    }
}

// MARK: - Tempo digits

/// The four tempo values, with the running phase's value lit and enlarged.
/// Sits in `WorkoutView`'s normal layout rather than inside the field, so
/// it participates in the stack like any other text.
struct TempoDigitRow: View {
    let engine: WorkoutEngine
    let phaseColor: Color
    var isCompact: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: isCompact ? Spacing.sm : Spacing.md) {
            ForEach(Array(engine.config.tempoDigits.enumerated()), id: \.offset) { index, value in
                let active = index == activeDigitIndex && engine.state == .running
                Text(verbatim: format(value))
                    .font(TempoFont.rounded(isCompact ? .body : .title3, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(active
                                     ? AnyShapeStyle(phaseColor)
                                     : AnyShapeStyle(Color.tempoPrimaryText.opacity(TempoOpacity.inactiveDigit)))
                    .scaleEffect(active && !reduceMotion ? TempoMetrics.Pacing.activeDigitScale : 1)
                    // The one place a spring belongs: a decorative
                    // scale-up, not the pacing itself.
                    .animation(reduceMotion ? nil : TempoAnimation.athleticPop, value: active)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Tempo"))
        .accessibilityValue(Text(verbatim: tempoAccessibilityReading(engine.config.tempoDigits)))
    }

    /// Index into `tempoDigits` for the phase currently running. The array
    /// is always in canonical order (control, bottom hold, drive, top
    /// hold) regardless of which phase a rep *starts* with, so this maps by
    /// phase rather than by position in the timeline.
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
        // 0...1 fraction digits rather than 0: whole seconds are the only
        // thing enterable now, but a legacy 1.5 must still read correctly
        // until the user next edits it.
        value.formatted(.number.locale(locale).precision(.fractionLength(0...1)))
    }
}

#Preview {
    ZStack {
        Color.tempoBackground.ignoresSafeArea()
        TempoPacingView(engine: WorkoutEngine(), phaseColor: .tempoControl)
        TempoDigitRow(engine: WorkoutEngine(), phaseColor: .tempoControl)
    }
}
