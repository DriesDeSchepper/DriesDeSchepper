import Testing
@testable import TempoRep

@MainActor
struct WorkoutEngineTests {

    @Test func bilateralTimelineBasicShape() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 0, 1, 0]
        config.repsPerSet = 2
        config.sets = 1
        config.unilateral = false

        let timeline = WorkoutEngine.buildTimeline(for: config)

        #expect(timeline.first?.phase == .getReady)
        let repPhases = timeline.dropFirst().map(\.phase)
        // Pauses are 0s and skipped entirely, leaving eccentric/concentric per rep.
        #expect(repPhases == [.eccentric, .concentric, .eccentric, .concentric])
        #expect(timeline.allSatisfy { $0.duration > 0 })
    }

    @Test func zeroDurationPhasesAreSkipped() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 0, 0, 0]
        config.repsPerSet = 1
        config.sets = 1

        let timeline = WorkoutEngine.buildTimeline(for: config)
        // Concentric digit 0 means explosive (1s), so it's NOT skipped; only the two 0s pauses are.
        #expect(timeline.map(\.phase) == [.getReady, .eccentric, .concentric])
    }

    @Test func explosiveConcentricIsOneSecond() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 0, 0, 0]
        config.repsPerSet = 1
        config.sets = 1

        let timeline = WorkoutEngine.buildTimeline(for: config)
        #expect(timeline.first { $0.phase == .concentric }?.duration == 1)
    }

    @Test func restAppearsBetweenSetsNotAfterLast() {
        var config = WorkoutConfig()
        config.tempoDigits = [1, 0, 1, 0]
        config.repsPerSet = 1
        config.sets = 3
        config.restSeconds = 45

        let timeline = WorkoutEngine.buildTimeline(for: config)
        #expect(timeline.filter { $0.phase == .rest }.count == 2) // between 1-2 and 2-3, not after set 3
        #expect(timeline.last?.phase != .rest)
    }

    @Test func estimatedDurationMatchesSegmentSum() {
        var config = WorkoutConfig()
        config.tempoDigits = [3, 1, 2, 1]
        config.repsPerSet = 4
        config.sets = 2
        config.restSeconds = 30

        let timeline = WorkoutEngine.buildTimeline(for: config)
        let expected = timeline.reduce(0) { $0 + $1.duration }
        #expect(WorkoutEngine.estimatedDuration(for: config) == expected)
        #expect(timeline.last?.end == expected)
    }

    @Test func unilateralDoesBothSidesWithinOneSetBeforeRest() {
        var config = WorkoutConfig()
        config.tempoDigits = [1, 0, 1, 0]
        config.repsPerSet = 2
        config.sets = 2
        config.unilateral = true
        config.switchSeconds = 10
        config.startingSide = .left

        let timeline = WorkoutEngine.buildTimeline(for: config)

        let firstSetSegments = timeline.prefix { $0.set == 1 }
        let sides = firstSetSegments.compactMap(\.side)
        #expect(sides.first == .left)
        #expect(sides.last == .right)

        guard let switchIndex = timeline.firstIndex(where: { $0.phase == .switchSides }),
              let restIndex = timeline.firstIndex(where: { $0.phase == .rest }) else {
            Issue.record("expected both a switch and a rest segment")
            return
        }
        #expect(switchIndex < restIndex)
        // The switch segment carries the *upcoming* side.
        #expect(timeline[switchIndex].side == .right)

        // Rep numbering resets per side rather than counting cumulatively.
        let leftReps = Set(timeline.filter { $0.side == .left && $0.rep > 0 }.map(\.rep))
        let rightReps = Set(timeline.filter { $0.side == .right && $0.rep > 0 }.map(\.rep))
        #expect(leftReps == rightReps)
        #expect(leftReps == [1, 2])
    }

    @Test func zeroSwitchTimeInsertsNoSwitchSegment() {
        var config = WorkoutConfig()
        config.tempoDigits = [1, 0, 1, 0]
        config.repsPerSet = 1
        config.sets = 1
        config.unilateral = true
        config.switchSeconds = 0

        let timeline = WorkoutEngine.buildTimeline(for: config)
        #expect(timeline.contains { $0.phase == .switchSides } == false)
    }

    @Test func bilateralHasNoSideOnAnySegment() {
        var config = WorkoutConfig()
        config.tempoDigits = [1, 0, 1, 0]
        config.repsPerSet = 2
        config.sets = 1
        config.unilateral = false

        let timeline = WorkoutEngine.buildTimeline(for: config)
        #expect(timeline.allSatisfy { $0.side == nil })
    }

    @Test func concentricStartPhaseReordersTheRep() {
        var config = WorkoutConfig()
        config.tempoDigits = [4, 1, 2, 1]
        config.repsPerSet = 1
        config.sets = 1
        config.startPhase = .concentric

        let timeline = WorkoutEngine.buildTimeline(for: config)
        let repPhases = timeline.dropFirst().map(\.phase) // drop getReady
        #expect(repPhases == [.concentric, .pauseTop, .eccentric, .pauseBottom])

        // The digits keep their usual meaning regardless of execution order.
        #expect(timeline.first { $0.phase == .eccentric }?.duration == 4)
        #expect(timeline.first { $0.phase == .concentric }?.duration == 2)
    }

    @Test func unilateralTimeUnderTensionIncludesSwitchPause() {
        // Mirrors the calculation in WorkoutEngine.finish(): both sides' rep
        // phases plus the switch pause, excluding rest and get-ready.
        var config = WorkoutConfig()
        config.tempoDigits = [1, 0, 1, 0]
        config.repsPerSet = 1
        config.sets = 1
        config.unilateral = true
        config.switchSeconds = 10

        let timeline = WorkoutEngine.buildTimeline(for: config)
        let timeUnderTension = timeline
            .filter { $0.rep > 0 || $0.phase == .switchSides }
            .reduce(0) { $0 + $1.duration }

        // 1s eccentric + 1s concentric per side (2s x 2 sides) + 10s switch = 14s.
        #expect(timeUnderTension == 14)
    }
}
