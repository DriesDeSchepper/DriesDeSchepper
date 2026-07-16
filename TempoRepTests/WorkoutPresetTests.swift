import Testing
@testable import TempoRep

struct WorkoutPresetTests {

    @Test func applySetsEveryFieldExceptVoiceCues() {
        let preset = WorkoutPreset(displayName: "Test", exerciseID: "Barbell_Deadlift",
                                    tempoDigits: [5, 0, 5, 0], repsPerSet: 5, sets: 5, restSeconds: 120,
                                    unilateral: false, switchSeconds: 10, startingSide: .left, startPhase: .concentric)

        var config = WorkoutConfig()
        config.voiceCues = false // deliberately not touched by apply()
        preset.apply(to: &config)

        #expect(config.tempoDigits == [5, 0, 5, 0])
        #expect(config.repsPerSet == 5)
        #expect(config.sets == 5)
        #expect(config.restSeconds == 120)
        #expect(config.unilateral == false)
        #expect(config.switchSeconds == 10)
        #expect(config.startingSide == .left)
        #expect(config.startPhase == .concentric)
        #expect(config.selectedExerciseID == "Barbell_Deadlift")
        #expect(config.voiceCues == false)
    }

    @Test func builtInPresetsReferenceExpectedExerciseIDs() {
        let ids = Set(WorkoutPreset.builtIn.compactMap(\.exerciseID))
        #expect(ids == ["Barbell_Squat", "Pushups", "Kettlebell_One-Legged_Deadlift", "Barbell_Deadlift"])
    }

    @Test func savedFromConfigCapturesCurrentState() {
        var config = WorkoutConfig()
        config.tempoDigits = [2, 0, 2, 0]
        config.unilateral = true
        config.selectedExerciseID = "Pushups"

        let preset = WorkoutPreset(displayName: "My Preset", config: config)
        #expect(preset.tempoDigits == [2, 0, 2, 0])
        #expect(preset.unilateral == true)
        #expect(preset.exerciseID == "Pushups")
        #expect(preset.displayName == "My Preset")
    }

    @Test func codableRoundTrip() throws {
        let preset = WorkoutPreset(displayName: "Custom", exerciseID: nil,
                                    tempoDigits: [3, 1, 1, 0], repsPerSet: 10, sets: 3, restSeconds: 60,
                                    unilateral: false, switchSeconds: 10, startingSide: .left, startPhase: .eccentric)

        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(WorkoutPreset.self, from: data)

        #expect(decoded.id == preset.id)
        #expect(decoded.displayName == preset.displayName)
        #expect(decoded.tempoDigits == preset.tempoDigits)
    }
}
