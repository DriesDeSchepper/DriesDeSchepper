import Foundation

/// A ready-to-run workout template: an exercise plus every setting that
/// goes with it. Unlike a plain tempo preset, applying one configures the
/// whole setup screen at once. `displayName` mirrors the underlying
/// exercise's (English) name for the built-ins; for user-saved presets it's
/// whatever name they typed. Deliberately excludes `voiceCues` — that's a
/// standing app-wide preference, not something a preset should override.
struct WorkoutPreset: Identifiable, Codable {
    let id: UUID
    let displayName: String
    let exerciseID: String?
    let tempoDigits: [Int]
    let repsPerSet: Int
    let sets: Int
    let restSeconds: Int
    let unilateral: Bool
    let switchSeconds: Int
    let startingSide: Side
    let startPhase: StartPhase

    init(id: UUID = UUID(), displayName: String, exerciseID: String?, tempoDigits: [Int],
         repsPerSet: Int, sets: Int, restSeconds: Int, unilateral: Bool, switchSeconds: Int,
         startingSide: Side, startPhase: StartPhase) {
        self.id = id
        self.displayName = displayName
        self.exerciseID = exerciseID
        self.tempoDigits = tempoDigits
        self.repsPerSet = repsPerSet
        self.sets = sets
        self.restSeconds = restSeconds
        self.unilateral = unilateral
        self.switchSeconds = switchSeconds
        self.startingSide = startingSide
        self.startPhase = startPhase
    }

    /// Captures everything a preset should from the current configuration —
    /// used when the user saves "what I have right now" as a named preset.
    init(displayName: String, config: WorkoutConfig) {
        self.init(displayName: displayName, exerciseID: config.selectedExerciseID,
                   tempoDigits: config.tempoDigits, repsPerSet: config.repsPerSet, sets: config.sets,
                   restSeconds: config.restSeconds, unilateral: config.unilateral,
                   switchSeconds: config.switchSeconds, startingSide: config.startingSide,
                   startPhase: config.startPhase)
    }

    func apply(to config: inout WorkoutConfig) {
        config.tempoDigits = tempoDigits
        config.repsPerSet = repsPerSet
        config.sets = sets
        config.restSeconds = restSeconds
        config.unilateral = unilateral
        config.switchSeconds = switchSeconds
        config.startingSide = startingSide
        config.startPhase = startPhase
        config.selectedExerciseID = exerciseID
    }

    static let builtIn: [WorkoutPreset] = [
        WorkoutPreset(displayName: "Squat", exerciseID: "Barbell_Squat",
                      tempoDigits: [4, 0, 1, 0], repsPerSet: 8, sets: 3, restSeconds: 90,
                      unilateral: false, switchSeconds: 10, startingSide: .left, startPhase: .eccentric),
        WorkoutPreset(displayName: "Push-Up", exerciseID: "Pushups",
                      tempoDigits: [3, 1, 1, 0], repsPerSet: 10, sets: 3, restSeconds: 60,
                      unilateral: false, switchSeconds: 10, startingSide: .left, startPhase: .eccentric),
        WorkoutPreset(displayName: "Single-Leg RDL", exerciseID: "Kettlebell_One-Legged_Deadlift",
                      tempoDigits: [2, 0, 2, 0], repsPerSet: 8, sets: 3, restSeconds: 90,
                      unilateral: true, switchSeconds: 10, startingSide: .left, startPhase: .concentric),
        WorkoutPreset(displayName: "Deadlift", exerciseID: "Barbell_Deadlift",
                      tempoDigits: [5, 0, 5, 0], repsPerSet: 5, sets: 5, restSeconds: 120,
                      unilateral: false, switchSeconds: 10, startingSide: .left, startPhase: .concentric),
    ]
}
