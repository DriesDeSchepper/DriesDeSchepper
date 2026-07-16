import Testing
@testable import TempoRep

struct WorkoutConfigTests {

    @Test func codableRoundTripPreservesAllFields() throws {
        var config = WorkoutConfig()
        config.tempoDigits = [5, 2, 3, 1]
        config.repsPerSet = 12
        config.sets = 4
        config.restSeconds = 75
        config.voiceCues = false
        config.unilateral = true
        config.switchSeconds = 15
        config.startingSide = .right
        config.startPhase = .concentric
        config.selectedExerciseID = "Barbell_Deadlift"

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(WorkoutConfig.self, from: data)

        #expect(decoded == config)
    }

    @Test func explosiveConcentricRule() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 0, 0, 0]
        #expect(config.concentricSeconds == 1)

        config.tempoDigits = [4, 0, 3, 0]
        #expect(config.concentricSeconds == 3)
    }

    @Test func tempoStringJoinsDigits() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 0, 1, 0]
        #expect(config.tempoString == "4010")
    }
}
