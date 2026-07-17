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

/// Values that aren't content rhythm: minimum tap targets (Apple's HIG
/// floor is 44pt) and the one deliberate layout offset that doesn't belong
/// on the spacing scale.
enum TempoMetrics {
    static let minTapTarget: CGFloat = 44
    /// Extra top padding on the setup screen, clearing space for where the
    /// title/icons used to sit before the splash screen took over that job.
    static let setupTopInset: CGFloat = 60
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

    /// `standard`, or `nil` (no animation) when the user has Reduce Motion
    /// enabled — callers that need a Reduce-Motion-aware crossfade instead
    /// of "no animation at all" should branch explicitly rather than use
    /// this for opacity-only changes.
    static func standard(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : standard
    }

    static func celebration(reduceMotion: Bool) -> Animation? {
        reduceMotion ? .easeInOut(duration: 0.25) : celebration
    }
}
