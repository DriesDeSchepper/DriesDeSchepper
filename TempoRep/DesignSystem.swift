import SwiftUI
import UIKit

// MARK: - Color

/// A dynamic color resolved per appearance, so a single token carries both
/// its light and dark value. Used instead of Asset Catalog colorsets so the
/// entire palette stays readable in one file — the whole point of this
/// being *the* token file.
private func adaptive(light: UInt32, dark: UInt32) -> Color {
    Color(uiColor: UIColor { traits in
        UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
    })
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Every color in the app derives from one of these — a semantic role, not
/// a literal RGB value used at a call site.
///
/// ## Two palettes that never co-star
///
/// **Signal** (the accent, in Assets.xcassets/AccentColor) owns setup,
/// history and calls to action. The **phase triad** — control / hold /
/// drive — owns a live rep, and while one is showing the surrounding
/// controls drop to neutral ink. Two saturated colors never compete on the
/// same screen; that restraint is the whole design system, and it's what
/// keeps a phase color unmissable from across a gym.
///
/// ## Light-first
///
/// Every screen follows the system appearance, including the workout
/// screen and splash, which previously forced dark. Each token below
/// therefore carries a deliberate value on both grounds rather than being
/// derived by inversion.
extension Color {
    // MARK: Ground and structure

    /// The page itself. Slightly off pure white / pure black, biased cool
    /// toward the ink so the neutrals read as chosen rather than default.
    static let tempoBackground = adaptive(light: 0xFBFBFC, dark: 0x0B0C0F)
    /// A raised card sitting above the background.
    static let tempoSurface = adaptive(light: 0xFFFFFF, dark: 0x14161B)
    /// An inset well — the opposite move from `tempoSurface`. Used for
    /// stat tiles and stepper fields that should read as recessed.
    static let tempoSunken = adaptive(light: 0xF2F3F6, dark: 0x1D2027)
    /// Hairline dividers and control borders.
    static let tempoRule = adaptive(light: 0xE3E5EA, dark: 0x23262E)

    static let tempoPrimaryText = Color.primary
    static let tempoSecondaryText = Color.secondary

    // MARK: Brand

    /// Text and glyphs on an accent-colored fill. The accent is dark enough
    /// in light mode to take white, and light enough in dark mode to need
    /// near-black — so this genuinely inverts rather than staying fixed.
    static let tempoOnAccent = adaptive(light: 0xFFFFFF, dark: 0x1A0209)

    // MARK: Phase triad

    /// Eccentric — the controlled, yielding half of the rep.
    static let tempoControl = adaptive(light: 0x7A3BEA, dark: 0xA47BFF)
    /// Either isometric hold, at the stretched or contracted end.
    static let tempoHold = adaptive(light: 0xC77700, dark: 0xFFB020)
    /// Concentric — the driving, overcoming half.
    static let tempoDrive = adaptive(light: 0x00934A, dark: 0x22C97A)
    /// Get-ready, rest and side-switch. Deliberately *not* a fourth hue:
    /// waiting isn't a phase of the rep, so it stays neutral and lets the
    /// triad mean something.
    static let tempoWaiting = Color.secondary

    // MARK: Semantic

    static let tempoDestructive = Color.red
    /// Reserved for future positive states (e.g. a personal best); defined
    /// now so one doesn't get invented ad hoc later.
    static let tempoSuccess = Color.green
    /// The phase colour for a tempo value by its position in the canonical
    /// [control, bottom hold, drive, top hold] array. Defined here so the
    /// setup screen, the history feed and the live workout all colour the
    /// same position identically.
    static func tempoPhase(at index: Int) -> Color {
        switch index {
        case 0: return .tempoControl
        case 2: return .tempoDrive
        default: return .tempoHold
        }
    }

    /// The filled favorite star. Deliberately not the accent — a yellow
    /// star is near-universal, and using Signal here would make favorited
    /// rows read as "selected" instead.
    static let tempoFavorite = adaptive(light: 0xE0A200, dark: 0xFFCC33)
}

// MARK: - Spacing

/// The only spacing values the app should use for content rhythm (padding,
/// stack spacing). Control sizing (tap targets) and one-off layout offsets
/// are intentionally not part of this scale — see `TempoMetrics`.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner radius

enum CornerRadius {
    static let sm: CGFloat = 14
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
}

// MARK: - Sizing

/// Fixed layout dimensions: things that aren't content rhythm (that's
/// `Spacing`) and don't scale with Dynamic Type. Minimum tap targets,
/// control sizes, and the fixed geometry of the workout display.
enum TempoMetrics {
    static let minTapTarget: CGFloat = 44
    /// The tempo-shape bar chart in a history row.
    static let tempoShapeHeight: CGFloat = 26
    static let tempoShapeBarRadius: CGFloat = 2
    static let tempoShapeWidth: CGFloat = 56
    /// A zero-second phase still draws this much, since "no pause" is
    /// information worth seeing rather than a gap.
    static let tempoShapeMinBar: CGFloat = 3

    /// Extra top padding on the setup screen, clearing space for where the
    /// title/icons used to sit before the splash screen took over that job.
    static let setupTopInset: CGFloat = 60

    // MARK: Workout display

    /// The countdown ring's diameter in portrait.
    static let ringDiameter: CGFloat = 300
    /// The countdown ring's diameter in `WorkoutView`'s landscape layout —
    /// smaller than portrait's, since landscape's constraint is height,
    /// not width.
    static let compactRingDiameter: CGFloat = 220
    static let ringLineWidth: CGFloat = 14
    /// The circular badge behind the finish-screen checkmark.
    static let completionBadgeDiameter: CGFloat = 130
    /// The thin gradient bar that flashes at the top edge on phase change.
    static let phaseFlashHeight: CGFloat = 3

    // MARK: Splash

    static let splashLogoDiameter: CGFloat = 96
    static let splashLogoLineWidth: CGFloat = 10

    // MARK: Controls

    /// The tempo digit box on the setup screen — wide enough for "1.5".
    static let digitBoxWidth: CGFloat = 64
    static let digitBoxHeight: CGFloat = 60
    /// The value readout between a `CounterRow`'s -/+ buttons.
    static let counterValueMinWidth: CGFloat = 64
    /// The value readout inside `CustomTempoView`'s inline stepper pill.
    static let stepperValueWidth: CGFloat = 44
    /// The starting-side segmented picker, which sits inline next to its
    /// label rather than filling the row.
    static let sidePickerWidth: CGFloat = 160

    // MARK: Tempo pacing field

    /// The full-bleed colour field that renders a rep — see
    /// `TempoPacingView`.
    enum Pacing {
        /// The bright line marking the lifted weight's position. Thin
        /// enough to read as a precise edge rather than a band.
        static let edgeThickness: CGFloat = 4
        /// Neon bloom on the edge: a tight inner glow plus a wider,
        /// fainter outer one, which is what keeps it reading as neon
        /// rather than as a drop shadow.
        static let glowRadius: CGFloat = 16
        static let glowRadiusOuter: CGFloat = 32
        /// Relative strength of the outer bloom against the inner one.
        static let outerGlowFactor: Double = 0.6

        /// How much the edge swells at the moment a phase changes.
        static let edgeSwellScale: CGFloat = 2.2
        /// Peak extra scale on an isometric hold's pulse.
        static let holdPulseAmplitude: CGFloat = 0.35
        /// Isometric hold pulse rate, in cycles per second. Deliberately
        /// close to a calm breathing cadence — this marks "hold still",
        /// so it should not read as urgency.
        static let holdPulseHz: Double = 0.8
        /// How much the active tempo value grows over the inactive three.
        static let activeDigitScale: CGFloat = 1.3

        // The phase-start swell is a damped oscillation rather than a
        // plain fade — the brief dip below full size is what reads as
        // spring. Higher decay settles sooner; the wobble rate sets how
        // many times it rings before settling.
        static let popDecayRate: Double = 7
        static let popWobbleHz: Double = 2.5
        /// Floor on the edge's scale, so the oscillation's undershoot can
        /// never collapse it to nothing.
        static let minEdgeScale: CGFloat = 0.6

        /// Drive durations at or above this many seconds are treated as
        /// "controlled" and get no ease-out at all — the lift should look
        /// as measured as it's meant to be performed. Below it, the
        /// ease-out fades in proportionally.
        static let explosiveThresholdSeconds: Double = 2
    }

    /// Point sizes for SF Symbol glyphs inside fixed-size controls. Not
    /// Dynamic-Type-scaled on purpose: the glyph sits inside a fixed tap
    /// target, so growing the glyph without growing its container would
    /// clip it. The label *next to* such a control always uses a real
    /// text style via `TempoFont`.
    enum Icon {
        static let small: CGFloat = 14
        static let medium: CGFloat = 16
        static let large: CGFloat = 18
        /// The finish-screen checkmark — a display glyph, not a control.
        static let celebration: CGFloat = 52
    }
}

// MARK: - Letter spacing

/// The app's only letter-spacing values. Used on the uppercase display
/// text (wordmark, phase titles, button labels) where tracking is part of
/// the look; ordinary prose never sets tracking at all.
enum TempoTracking {
    /// Small-caps labels (a side badge, "PAUSED").
    static let label: CGFloat = 2
    /// Uppercase button labels (START, CONTINUE).
    static let button: CGFloat = 3
    /// The finish-screen title.
    static let title: CGFloat = 4
    /// The splash wordmark — the widest, since it's the largest text.
    static let wordmark: CGFloat = 8
}

// MARK: - Opacity

/// Opacity values applied to *content* (text, fills). Surface tints live
/// in the `Color` tokens above instead, since those are colors in their
/// own right rather than a modifier on something else.
enum TempoOpacity {
    /// De-emphasized detail that still sits on a colored chip, where
    /// `.secondary` would fight the chip's own tint.
    static let secondaryDetail: Double = 0.7
    /// The soft accent-colored disc behind the finish-screen checkmark.
    static let badgeFill: Double = 0.15
    /// The three tempo digits that aren't the phase currently running.
    static let inactiveDigit: Double = 0.3
    /// The pacing field, at its densest (against the bottom edge) and
    /// its faintest (just under the moving edge line). Deliberately low:
    /// the numerals sit on top of this and must stay legible at every
    /// fill level, on both grounds.
    static let fieldBase: Double = 0.22
    static let fieldTop: Double = 0.07
    /// The edge line's neon bloom at full intensity.
    static let pacingGlow: Double = 0.55
}

// MARK: - Text scaling

/// Floors for `minimumScaleFactor` on text that must not wrap or clip —
/// the oversized workout display faces, and the tempo digit box. A lower
/// floor means the text is allowed to shrink further before truncating.
enum TempoScaleFactor {
    /// The countdown numerals and landscape phase title, which have the
    /// least room and the most size variation.
    static let display: CGFloat = 0.4
    /// The portrait phase title.
    static let title: CGFloat = 0.5
    /// The finish-screen title.
    static let finishedTitle: CGFloat = 0.6
    /// The setup screen's tempo digit box.
    static let digit: CGFloat = 0.7
}

// MARK: - Typography

/// Every font in the app goes through here. Regular UI text uses system
/// Dynamic Type text styles (so it grows/shrinks with the user's text-size
/// setting) in the app's rounded design. The oversized workout-display
/// faces (countdown ring, phase title) don't map to a standard text style —
/// they're intentionally larger than `.largeTitle` — so those use
/// `@ScaledMetric` at the call site instead, seeded from the base sizes
/// below, which still scales with Dynamic Type while preserving the
/// "readable across a room" design.
enum TempoFont {
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

/// Base point sizes for the display faces that use `@ScaledMetric` instead
/// of a text style. Each consuming view declares its own
/// `@ScaledMetric(wrappedValue: TempoMetrics.Display.x, relativeTo: ...)`.
extension TempoMetrics {
    enum Display {
        static let countdown: CGFloat = 96
        /// Countdown digit size to match `TempoMetrics.compactRingDiameter`
        /// in landscape — reusing the portrait 96pt inside a 220pt ring
        /// (vs. portrait's 300pt) would look undersized relative to the
        /// smaller ring.
        static let countdownCompact: CGFloat = 64
        static let phaseTitle: CGFloat = 54
        static let phaseSubtitle: CGFloat = 20
        static let digit: CGFloat = 40
        static let finishedTitle: CGFloat = 56
        static let splashWordmark: CGFloat = 40
        static let splashDigit: CGFloat = 44
        /// The finish screen's headline figure — larger than any text
        /// style, so it scales via `@ScaledMetric` like the countdown.
        static let statHero: CGFloat = 76
    }
}

// MARK: - Motion

/// One standard duration + curve for routine UI-state transitions (a
/// section appearing, a screen crossfade). `celebration` is a deliberate,
/// separate exception for the one-off finish-screen checkmark — a
/// congratulatory flourish, not a state transition — and is skipped
/// entirely (replaced with a plain crossfade) when Reduce Motion is on.
enum TempoAnimation {
    static let standard: Animation = .easeInOut(duration: 0.25)
    static let celebration: Animation = .spring(response: 0.5, dampingFraction: 0.62)
    /// The phase-change flash's fade-out. Longer than `standard` on
    /// purpose: it's a decorative glow that should linger and trail off,
    /// not a state transition that should feel snappy.
    static let phaseFlashFade: Animation = .easeOut(duration: 0.6)

    /// How long the finish screen's time-under-tension counts up from
    /// zero. Long enough to register as an earned total rather than a
    /// number that was simply printed.
    static let countUpDuration: TimeInterval = 0.9

    /// Snappy, slightly overshooting spring for the pacing dot's pop and
    /// the active tempo digit's scale-up.
    ///
    /// Deliberately applied *only* to decorative properties — scale and
    /// glow — never to the dot's position along the track. A spring
    /// settles in its own time (~0.4s here) no matter how long the phase
    /// actually is, so springing the position would show a 3-second
    /// concentric finishing in under half a second. Position is the one
    /// thing on this screen that has to stay literally true to the clock,
    /// so it's interpolated from the engine's elapsed-time progress
    /// instead. See `TempoPacingView`.
    static let athleticPop: Animation = .spring(response: 0.25, dampingFraction: 0.5)

    /// `standard`, or `nil` (no animation) when the user has Reduce Motion
    /// enabled — callers that need a Reduce-Motion-aware crossfade instead
    /// of "no animation at all" should branch explicitly rather than use
    /// this for opacity-only changes.
    static func standard(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : standard
    }

    /// The celebration spring, or a plain `standard` crossfade under
    /// Reduce Motion — the checkmark still appears, it just doesn't pop.
    static func celebration(reduceMotion: Bool) -> Animation? {
        reduceMotion ? standard : celebration
    }
}
