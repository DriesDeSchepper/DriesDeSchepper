import Foundation

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
    /// Tempo digits: [eccentric, pause at bottom, concentric, pause at top].
    var tempoDigits: [Int] = [4, 0, 1, 0]
    var repsPerSet: Int = 8
    var sets: Int = 3
    var restSeconds: Int = 90
    var voiceCues: Bool = true
    var unilateral: Bool = false
    /// Pause between sides, in seconds. 0 = immediate, no dedicated pause.
    var switchSeconds: Int = 10
    var startingSide: Side = .left
    var startPhase: StartPhase = .eccentric
    /// ID into the bundled exercise database (Resources/exercises.json); nil
    /// runs a bare timer with no exercise attached.
    var selectedExerciseID: String?

    /// A concentric digit of 0 means "explosive" — timed as 1 second.
    var concentricSeconds: Int { tempoDigits[2] == 0 ? 1 : tempoDigits[2] }

    var tempoString: String { tempoDigits.map(String.init).joined() }

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
    let tempoDigits: [Int]
    let sets: Int
    let repsPerSet: Int
    let restSeconds: Int
    /// Total seconds spent inside rep phases (excludes rest and get-ready).
    let timeUnderTension: TimeInterval
    let totalDuration: TimeInterval

    var tempoString: String { tempoDigits.map(String.init).joined() }
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
