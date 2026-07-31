import Testing
import Foundation
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

    @Test func reverseDirectionRoundTripsThroughApplyAndSave() {
        let preset = WorkoutPreset(displayName: "Lat Pulldown", exerciseID: nil,
                                    tempoDigits: [2, 0, 1, 0], repsPerSet: 10, sets: 3, restSeconds: 60,
                                    unilateral: false, switchSeconds: 10, startingSide: .left,
                                    startPhase: .eccentric, reverseDirection: true)
        var config = WorkoutConfig()
        preset.apply(to: &config)
        #expect(config.reverseDirection == true)

        let saved = WorkoutPreset(displayName: "Saved", config: config)
        #expect(saved.reverseDirection == true)
    }

    /// A preset saved before `reverseDirection` existed must still decode.
    /// Synthesized Codable would hard-fail on the missing key — and
    /// `PresetStore.load()` swallows decode errors, so that failure would
    /// silently wipe every preset the user had saved.
    @Test func decodesPresetSavedBeforeReverseDirectionExisted() throws {
        let legacyJSON = """
        {
          "id": "8B2A1F6E-0000-4000-A000-000000000001",
          "displayName": "Legacy",
          "tempoDigits": [4, 0, 1, 0],
          "repsPerSet": 8,
          "sets": 3,
          "restSeconds": 90,
          "unilateral": false,
          "switchSeconds": 10,
          "startingSide": "left",
          "startPhase": "eccentric"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(WorkoutPreset.self, from: legacyJSON)
        #expect(decoded.displayName == "Legacy")
        #expect(decoded.reverseDirection == false)
        // Integers in old JSON still decode into the now-Double tempo values.
        #expect(decoded.tempoDigits == [4, 0, 1, 0])
    }

    @Test func reverseDirectionDefaultsToFalseWhenOmitted() {
        let preset = WorkoutPreset(displayName: "Test", exerciseID: nil,
                                    tempoDigits: [3, 0, 1, 0], repsPerSet: 8, sets: 3, restSeconds: 60,
                                    unilateral: false, switchSeconds: 10, startingSide: .left, startPhase: .eccentric)
        #expect(preset.reverseDirection == false)
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
