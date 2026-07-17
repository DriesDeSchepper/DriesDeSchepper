import Foundation

/// One entry from the bundled free-exercise-db dataset (public domain,
/// https://github.com/yuhonas/free-exercise-db), trimmed to what the app
/// needs. Names/categories/muscles/equipment are English-only in the source
/// data and are shown as-is regardless of the app's language.
struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: String
    let equipment: String?
    let primaryMuscles: [String]
    /// Heuristic, computed once when the bundled dataset was built: true for
    /// exercises whose name indicates a single-limb movement (e.g. "One-Arm
    /// Dumbbell Row", "Single-Leg Calf Raise").
    let isUnilateral: Bool
    /// Heuristic: exercises like deadlifts and pull-ups start the rep by
    /// lifting, not lowering, so their suggested tempo sequence leads with
    /// the concentric phase.
    let startPhase: StartPhase

    /// A general-purpose starting tempo for this exercise's primary muscle
    /// group, offered as a suggestion the user can freely override — not a
    /// claim about a single scientifically "correct" tempo. Small,
    /// single-joint muscle groups (calves, arms, forearms) tend to respond
    /// well to a slower eccentric with a brief pause at full stretch and an
    /// explosive concentric; core/lower-back work favors staying controlled
    /// through the whole rep; everything else defaults to a standard
    /// hypertrophy tempo. Only offered for resistance-training categories —
    /// tempo manipulation isn't a meaningful concept for stretching,
    /// plyometrics, cardio, or Olympic lifts.
    var suggestedTempo: [Int]? {
        guard category == "strength" || category == "powerlifting" else { return nil }
        guard let muscle = primaryMuscles.first else { return nil }
        switch muscle {
        case "calves", "biceps", "triceps", "forearms":
            return [4, 2, 0, 0]
        case "abdominals", "lower back":
            return [3, 1, 2, 1]
        default:
            return [3, 0, 1, 0]
        }
    }
}
