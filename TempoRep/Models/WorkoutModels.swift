import Foundation

/// A single tempo value formatted without a pointless trailing ".0" —
/// whole seconds read as "4", half-seconds as "1.5".
private func formatTempoValue(_ value: Double) -> String {
    value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
}

/// Tempo digits formatted with direction arrows and dot separators
/// (e.g. "↓4·0·↑1·0") instead of a bare joined string — clearer at a
/// glance about which number is eccentric (lowering) vs. concentric
/// (lifting). Digits and separators are locale-independent (plain
/// numerals and symbols), so this doesn't go through the string catalog.
///
/// `reversed` swaps which arrow marks which phase: for exercises where
/// the physical motion isn't visually "eccentric = down" (a lat pulldown
/// or leg curl contracts by moving *down*), reversing lets the arrows
/// still match what the lifter actually sees. It never changes which
/// digit means what — only which glyph is drawn next to it.
func tempoNotation(_ digits: [Double], reversed: Bool = false) -> String {
    guard digits.count == 4 else { return digits.map(formatTempoValue).joined() }
    let (eccArrow, conArrow) = reversed ? ("↑", "↓") : ("↓", "↑")
    let values = digits.map(formatTempoValue)
    return "\(eccArrow)\(values[0])·\(values[1])·\(conArrow)\(values[2])·\(values[3])"
}

/// A VoiceOver-friendly reading of tempo digits ("4-0-1-0", or "1.5-0-1-0"
/// with a half-second value) — the arrow/dot symbols in `tempoNotation`
/// aren't reliably spoken by VoiceOver, so anywhere that notation is shown
/// as text supplies this instead via an explicit accessibility label.
/// Direction-agnostic on purpose: VoiceOver users get the plain digit
/// sequence regardless of `reversed`, same as sighted users would get the
/// same 4 numbers regardless of which way the arrows point.
func tempoAccessibilityReading(_ digits: [Double]) -> String {
    digits.map(formatTempoValue).joined(separator: "-")
}

/// Which phase a rep's tempo sequence leads with. Most lifts lower first
/// (eccentric); a few — deadlifts, pull-ups — start by lifting from a dead
/// stop, so their tempo sequence leads with the concentric phase instead.
/// Either way the 4 tempo digits keep their usual meaning (1st = eccentric
/// duration, 3rd = concentric duration, etc.) — only the execution order
/// within a rep changes.
enum StartPhase: String, Codable {
    case eccentric
    case concentric
}

/// User-configurable workout parameters.
struct WorkoutConfig: Equatable, Codable {
    /// Tempo digits, in seconds: [eccentric, pause at bottom, concentric,
    /// pause at top]. Supports half-second steps (e.g. 1.5).
    var tempoDigits: [Double] = [4, 0, 1, 0]
    var repsPerSet: Int = 8
    var sets: Int = 3
    var restSeconds: Int = 90
    var voiceCues: Bool = true
    var unilateral: Bool = false
    /// Pause between sides, in seconds. 0 = immediate, no dedicated pause.
    var switchSeconds: Int = 10
    var startingSide: Side = .left
    var startPhase: StartPhase = .eccentric
    /// Swaps which arrow/voice-word marks eccentric vs. concentric, for
    /// exercises where the physical motion runs the "other way" visually
    /// (lat pulldowns, leg curls). Doesn't affect timing at all — see
    /// `tempoNotation(_:reversed:)` and `Phase.voiceWord(_:reversed:)`.
    var reverseDirection: Bool = false
    /// ID into the bundled exercise database (Resources/exercises.json); nil
    /// runs a bare timer with no exercise attached.
    var selectedExerciseID: String?

    /// A concentric digit of 0 means "explosive" — timed as 1 second.
    var concentricSeconds: Double { tempoDigits[2] == 0 ? 1 : tempoDigits[2] }

    var tempoString: String { tempoNotation(tempoDigits, reversed: reverseDirection) }

    // MARK: - Codable

    init() {}

    /// Hand-written rather than synthesized: Swift's synthesized decoding
    /// *ignores* a property's default value and hard-fails on a missing
    /// key, so adding any new field would make every previously-saved
    /// config fail to decode — silently resetting the user's settings,
    /// since `loadSaved()` swallows the error. Decoding each field with
    /// `decodeIfPresent` and falling back to the declared default keeps
    /// old saved data readable across schema changes.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = WorkoutConfig()
        tempoDigits = try container.decodeIfPresent([Double].self, forKey: .tempoDigits) ?? defaults.tempoDigits
        repsPerSet = try container.decodeIfPresent(Int.self, forKey: .repsPerSet) ?? defaults.repsPerSet
        sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? defaults.sets
        restSeconds = try container.decodeIfPresent(Int.self, forKey: .restSeconds) ?? defaults.restSeconds
        voiceCues = try container.decodeIfPresent(Bool.self, forKey: .voiceCues) ?? defaults.voiceCues
        unilateral = try container.decodeIfPresent(Bool.self, forKey: .unilateral) ?? defaults.unilateral
        switchSeconds = try container.decodeIfPresent(Int.self, forKey: .switchSeconds) ?? defaults.switchSeconds
        startingSide = try container.decodeIfPresent(Side.self, forKey: .startingSide) ?? defaults.startingSide
        startPhase = try container.decodeIfPresent(StartPhase.self, forKey: .startPhase) ?? defaults.startPhase
        reverseDirection = try container.decodeIfPresent(Bool.self, forKey: .reverseDirection) ?? defaults.reverseDirection
        selectedExerciseID = try container.decodeIfPresent(String.self, forKey: .selectedExerciseID)
    }

    // MARK: - Persistence

    private static let defaultsKey = "workoutConfig"

    /// Returns the last-used configuration, or defaults on first launch
    /// (or if the stored data doesn't decode).
    static func loadSaved() -> WorkoutConfig {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode(WorkoutConfig.self, from: data),
              decoded.tempoDigits.count == 4 else {
            return WorkoutConfig()
        }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}

enum Side: String, Codable, CaseIterable, Identifiable {
    case left, right
    var id: String { rawValue }
    var opposite: Side { self == .left ? .right : .left }

    func label(_ locale: Locale) -> String {
        switch self {
        case .left: return L("Left", locale)
        case .right: return L("Right", locale)
        }
    }
}

/// One completed workout, as shown on the history screen.
struct WorkoutRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    /// The exercise's name at the time of the workout (denormalized, not an
    /// ID lookup) so history stays accurate even if the bundled dataset
    /// ever changes. Optional and defaults to nil when decoding older
    /// records saved before this field existed.
    let exerciseName: String?
    let tempoDigits: [Double]
    let sets: Int
    let repsPerSet: Int
    let restSeconds: Int
    /// Total seconds spent inside rep phases (excludes rest and get-ready).
    let timeUnderTension: TimeInterval
    let totalDuration: TimeInterval

    var tempoString: String { tempoNotation(tempoDigits) }
}

enum Phase: Equatable {
    case getReady
    case eccentric
    case pauseBottom
    case concentric
    case pauseTop
    case rest
    case switchSides
    case done

    /// Localized display strings. These aren't SwiftUI `Text`, so unlike
    /// most of the app's UI text they can't rely on the `\.locale`
    /// environment — the caller passes the locale explicitly (from
    /// `@Environment(\.locale)` in a View, or `LocalizationManager` in the
    /// engine, which also needs these for voice cues).
    func title(_ locale: Locale) -> String {
        switch self {
        case .getReady: return L("phase.getReady.title", locale)
        case .eccentric: return L("phase.eccentric.title", locale)
        case .pauseBottom, .pauseTop: return L("phase.pause.title", locale)
        case .concentric: return L("phase.concentric.title", locale)
        case .rest: return L("phase.rest.title", locale)
        case .switchSides: return L("phase.switchSides.title", locale)
        case .done: return L("phase.done.title", locale)
        }
    }

    func subtitle(_ locale: Locale) -> String {
        switch self {
        case .getReady: return L("phase.getReady.subtitle", locale)
        case .eccentric: return L("phase.eccentric.subtitle", locale)
        case .pauseBottom, .pauseTop: return L("phase.pause.subtitle", locale)
        case .concentric: return L("phase.concentric.subtitle", locale)
        case .rest: return L("phase.rest.subtitle", locale)
        case .switchSides: return L("phase.switchSides.subtitle", locale)
        case .done: return L("phase.done.subtitle", locale)
        }
    }

    func voiceWord(_ locale: Locale) -> String {
        switch self {
        case .getReady: return L("phase.getReady.voice", locale)
        case .eccentric: return L("phase.eccentric.voice", locale)
        case .pauseBottom, .pauseTop: return L("phase.pause.voice", locale)
        case .concentric: return L("phase.concentric.voice", locale)
        case .rest: return L("phase.rest.voice", locale)
        case .switchSides: return L("phase.switchSides.voice", locale)
        case .done: return L("phase.done.voice", locale)
        }
    }

    /// `voiceWord(_:)`, honoring `reverseDirection` — when the physical
    /// motion runs "the other way" (a lat pulldown's concentric phase
    /// pulls *down*), the spoken word should match what the lifter is
    /// actually doing, not just the phase's usual label. Only eccentric
    /// and concentric ever swap; every other phase is direction-neutral.
    func voiceWord(_ locale: Locale, reversed: Bool) -> String {
        guard reversed else { return voiceWord(locale) }
        switch self {
        case .eccentric: return Phase.concentric.voiceWord(locale)
        case .concentric: return Phase.eccentric.voiceWord(locale)
        default: return voiceWord(locale)
        }
    }
}

/// One slice of the precomputed workout timeline.
struct Segment {
    let phase: Phase
    let rep: Int    // 1-based; 0 for non-rep segments (get ready / rest / switch)
    let set: Int    // 1-based
    /// The side a rep segment belongs to (nil for bilateral work). A
    /// `.switchSides` segment carries the *upcoming* side, so the UI can
    /// show "up next: Right" during the pause.
    let side: Side?
    let start: TimeInterval
    let duration: TimeInterval
    var end: TimeInterval { start + duration }
}
