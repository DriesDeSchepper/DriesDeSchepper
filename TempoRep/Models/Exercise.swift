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
}
