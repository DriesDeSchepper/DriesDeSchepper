import Foundation

/// A ready-to-run workout template: an exercise plus every setting that
/// goes with it. Unlike a plain tempo preset, applying one configures the
/// whole setup screen at once. `displayName` mirrors the underlying
/// exercise's (English) name, consistent with exercise names elsewhere.
struct WorkoutPreset: Identifiable {
    let id = UUID()
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
