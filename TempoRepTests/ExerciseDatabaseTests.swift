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
        // Regression check for a UI bug (not a data bug): triceps must be
        // present and reachable through the same filter list.
        #expect(db.allMuscles.contains("triceps"))
    }

    @Test func suggestedTempoFavorsExplosiveConcentricForSmallMuscles() {
        let db = ExerciseDatabase.shared
        #expect(db.exercise(id: "Balance_Board")?.suggestedTempo == [4, 2, 0, 0])
    }

    @Test func suggestedTempoStaysControlledForCore() {
        let db = ExerciseDatabase.shared
        #expect(db.exercise(id: "3_4_Sit-Up")?.suggestedTempo == [3, 1, 2, 1])
    }

    @Test func suggestedTempoDefaultsForCompoundMuscles() {
        let db = ExerciseDatabase.shared
        #expect(db.exercise(id: "Barbell_Full_Squat")?.suggestedTempo == [3, 0, 1, 0])
    }

    @Test func suggestedTempoIsNilOutsideResistanceCategories() {
        let db = ExerciseDatabase.shared
        #expect(db.exercise(id: "90_90_Hamstring")?.category == "stretching")
        #expect(db.exercise(id: "90_90_Hamstring")?.suggestedTempo == nil)
    }

    @Test func togglingFavoriteFlipsMembershipAndListing() {
        let db = ExerciseDatabase.shared
        guard let exercise = db.exercise(id: "Barbell_Squat") else {
            Issue.record("missing preset exercise Barbell_Squat")
            return
        }
        let wasFavorite = db.isFavorite(exercise)
        defer { if db.isFavorite(exercise) != wasFavorite { db.toggleFavorite(exercise) } }

        db.toggleFavorite(exercise)
        #expect(db.isFavorite(exercise) == !wasFavorite)
        #expect(db.favorites.contains { $0.id == exercise.id } == !wasFavorite)

        db.toggleFavorite(exercise)
        #expect(db.isFavorite(exercise) == wasFavorite)
    }
}
