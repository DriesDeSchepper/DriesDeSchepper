import SwiftUI

// MARK: - Color

/// Every color in the app derives from one of these. There is exactly one
/// accent color (defined once, in Assets.xcassets/AccentColor) — everything
/// else is a semantic role, not a literal RGB value, so it can adapt to
/// light/dark mode (and to any future accent-color change) from one place.
///
/// `background`/`surface`/`primaryText`/`secondaryText` resolve via system
/// semantic colors, so Setup, Settings, History, and the exercise picker
/// follow the user's system appearance automatically. The workout screen
/// (`WorkoutView`) and the launch splash are the one deliberate exception:
/// they force dark regardless of system setting, because the giant
/// countdown display is designed to be read at a glance from across a gym,
/// and a sudden white flash mid-set would be actively hostile. That's
/// requested explicitly via `Color.tempoWorkoutBackground` / `.tempoOnDark`,
/// never by accident — see `WorkoutView.body`'s `.preferredColorScheme(.dark)`.
extension Color {
    /// Screen background for light/dark-adaptive screens.
    static let tempoBackground = Color(.systemBackground)
    /// A raised card/row, one step above the background.
    static let tempoSurface = Color.primary.opacity(0.06)
    /// A slightly more prominent raised surface (chips, steppers, filled controls).
    static let tempoSurfaceRaised = Color.primary.opacity(0.10)

    static let tempoPrimaryText = Color.primary
    static let tempoSecondaryText = Color.secondary

    static let tempoDestructive = Color.red
    /// Reserved for future positive/success states (e.g. a new personal
    /// best); not yet used anywhere, defined now so one doesn't get
    /// invented ad hoc later.
    static let tempoSuccess = Color.green

    /// Text and glyphs sitting *on top of* an accent-colored fill (the
    /// START / Pause / Continue buttons). Fixed black rather than
    /// `.primary`: the accent is a bright, saturated color in both
    /// appearances, and black clears WCAG AA contrast against either of
    /// AccentColor's light/dark variants, where `.primary` would invert
    /// to white in dark mode and fail.
    static let tempoOnAccent = Color.black
    /// The filled favorite star. Deliberately *not* the accent color —
    /// a star being yellow is a near-universal convention, and using the
    /// accent here would make favorited rows read as "selected" instead.
    static let tempoFavorite = Color.yellow

    /// Fixed black background for the always-dark screens (workout, splash).
    /// Deliberately a literal, not `.tempoBackground` — those screens never
    /// follow the system appearance.
    static let tempoWorkoutBackground = Color.black
    /// Primary text on the always-dark screens. Also a deliberate literal:
    /// `.primary` would flip to black-on-black if a future screen using
    /// this token ever inherited a light color scheme by mistake.
    static let tempoOnDark = Color.white
    /// Raised surfaces on the always-dark screens (the progress ring's
    /// track, the Stop button) — fixed-white-based, unlike `.tempoSurface`,
    /// since these never adapt.
    static let tempoOnDarkSurface = Color.white.opacity(0.1)
    static let tempoOnDarkSurfaceRaised = Color.white.opacity(0.12)

    /// The one deliberate second brand color, workout-screen-only: the
    /// eccentric (lowering) phase is tinted violet instead of the regular
    /// accent green, so the two halves of a rep read apart at a glance —
    /// concentric (lifting) keeps using the regular `.accentColor`, since
    /// that's already green and "lifting" is the phase the accent color
    /// was chosen around. Named and defined once here for the same reason
    /// every other color is: so nothing reinvents this shade ad hoc.
    static let tempoEccentric = Color(red: 0.55, green: 0.35, blue: 1.0)
    /// The get-ready countdown's color — distinct from both rep-phase
    /// colors above so "you're about to start" reads as its own state,
    /// not a third variant of eccentric/concentric.
    static let tempoGetReady = Color(red: 0.3, green: 0.55, blue: 1.0)
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
