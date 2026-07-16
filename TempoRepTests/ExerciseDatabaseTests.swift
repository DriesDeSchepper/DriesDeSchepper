import Testing
@testable import TempoRep

@MainActor
struct ExerciseDatabaseTests {

    @Test func bundledDatasetLoadsWithExpectedShape() {
        let db = ExerciseDatabase.shared
        #expect(db.exercises.count > 800)

        let ids = db.exercises.map(\.id)
        #expect(Set(ids).count == ids.count) // no duplicate IDs

        #expect(db.exercises.allSatisfy { $0.name.isEmpty == false })
    }

    @Test func presetExercisesExistInTheDatabase() {
        let db = ExerciseDatabase.shared
        for id in ["Barbell_Squat", "Pushups", "Kettlebell_One-Legged_Deadlift", "Barbell_Deadlift"] {
            #expect(db.exercise(id: id) != nil, "missing preset exercise \(id)")
        }
    }

    @Test func knownUnilateralAndConcentricHeuristics() {
        let db = ExerciseDatabase.shared
        #expect(db.exercise(id: "Barbell_Deadlift")?.startPhase == .concentric)
        #expect(db.exercise(id: "Kettlebell_One-Legged_Deadlift")?.isUnilateral == true)
        // A plain bilateral, eccentric-first exercise as a control case.
        #expect(db.exercise(id: "Barbell_Squat")?.isUnilateral == false)
        #expect(db.exercise(id: "Barbell_Squat")?.startPhase == .eccentric)
    }

    @Test func exerciseLookupWithNilIDReturnsNil() {
        #expect(ExerciseDatabase.shared.exercise(id: nil) == nil)
    }

    @Test func filtersCoverKnownMuscleAndEquipment() {
        let db = ExerciseDatabase.shared
        #expect(db.allMuscles.contains("quadriceps"))
        #expect(db.allEquipment.contains("barbell"))
    }
}
