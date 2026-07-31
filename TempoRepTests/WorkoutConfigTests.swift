import Testing
import Foundation
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

    @Test func tempoStringUsesDirectionalNotation() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 0, 1, 0]
        #expect(config.tempoString == "↓4·0·↑1·0")
    }

    @Test func tempoAccessibilityReadingIsPlainDashJoined() {
        #expect(tempoAccessibilityReading([4, 0, 1, 0]) == "4-0-1-0")
    }

    @Test func tempoStringSupportsHalfSecondValues() {
        var config = WorkoutConfig()
        config.tempoDigits = [3, 0, 1.5, 0]
        #expect(config.tempoString == "↓3·0·↑1.5·0")
        #expect(tempoAccessibilityReading(config.tempoDigits) == "3-0-1.5-0")
    }

    @Test func reverseDirectionSwapsArrowsNotDigitMeaning() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 0, 1, 0]
        #expect(config.tempoString == "↓4·0·↑1·0")

        config.reverseDirection = true
        #expect(config.tempoString == "↑4·0·↓1·0")
        // The digits themselves — and what they mean — never change.
        #expect(config.tempoDigits == [4, 0, 1, 0])
    }

    @Test func reverseDirectionDefaultsToFalse() {
        #expect(WorkoutConfig().reverseDirection == false)
    }

    /// A config saved before `reverseDirection` existed must still decode
    /// (and keep the user's other settings) rather than silently resetting
    /// everything to defaults — see `WorkoutConfig.init(from:)`.
    @Test func decodesConfigSavedBeforeReverseDirectionExisted() throws {
        let legacyJSON = """
        {
          "tempoDigits": [5, 2, 3, 1],
          "repsPerSet": 12,
          "sets": 4,
          "restSeconds": 75,
          "voiceCues": false,
          "unilateral": true,
          "switchSeconds": 15,
          "startingSide": "right",
          "startPhase": "concentric"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(WorkoutConfig.self, from: legacyJSON)
        #expect(decoded.reverseDirection == false)
        #expect(decoded.tempoDigits == [5, 2, 3, 1])
        #expect(decoded.repsPerSet == 12)
        #expect(decoded.voiceCues == false)
        #expect(decoded.startingSide == .right)
    }

    @Test func reversedVoiceWordSwapsEccentricAndConcentricOnly() {
        let locale = Locale(identifier: "en")
        #expect(Phase.eccentric.voiceWord(locale, reversed: true) == Phase.concentric.voiceWord(locale))
        #expect(Phase.concentric.voiceWord(locale, reversed: true) == Phase.eccentric.voiceWord(locale))
        #expect(Phase.rest.voiceWord(locale, reversed: true) == Phase.rest.voiceWord(locale))
        #expect(Phase.eccentric.voiceWord(locale, reversed: false) == Phase.eccentric.voiceWord(locale))
    }
}
