import Testing
import Foundation
@testable import TempoRep

/// The pacing track's *look* can only be judged on a device, but the
/// arithmetic behind it is testable — and it's the part that would make
/// the app lie about pacing if it were wrong. These mirror
/// `TempoPacingView`'s `driveEasing` and position mapping.
struct TempoPacingTests {

    // MARK: - Easing

    /// Mirrors `TempoPacingView.driveEasing`.
    private func easing(_ progress: Double, driveSeconds: Double) -> Double {
        let threshold = TempoMetrics.Pacing.explosiveThresholdSeconds
        let explosiveness = max(0, min(1, (threshold - driveSeconds) / threshold))
        let easedOut = 1 - pow(1 - progress, 3)
        return progress + explosiveness * (easedOut - progress)
    }

    /// The whole point of easing rather than springing: however aggressive
    /// the curve, the dot must start at the bottom and arrive at the top
    /// exactly as the phase ends. Any drift here means the visual finishes
    /// early or late against the spoken cue.
    @Test(arguments: [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0])
    func easingAlwaysSpansTheFullPhase(driveSeconds: Double) {
        #expect(easing(0, driveSeconds: driveSeconds) == 0)
        #expect(abs(easing(1, driveSeconds: driveSeconds) - 1) < 1e-9)
    }

    @Test(arguments: [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0])
    func easingIsMonotonic(driveSeconds: Double) {
        var previous = -1.0
        for step in 0...100 {
            let value = easing(Double(step) / 100, driveSeconds: driveSeconds)
            #expect(value >= previous, "went backwards at \(step)% for \(driveSeconds)s")
            previous = value
        }
    }

    /// A controlled (2s+) drive should track real time exactly — no
    /// ease-out at all, because a slow lift ought to look slow.
    @Test func controlledDriveIsLinear() {
        for step in 0...10 {
            let p = Double(step) / 10
            #expect(abs(easing(p, driveSeconds: 3) - p) < 1e-9)
        }
    }

    /// An explosive drive should visibly launch: well past halfway
    /// by the time a third of the phase has elapsed.
    @Test func explosiveDriveFrontLoadsTheTravel() {
        let explosive = easing(1.0 / 3.0, driveSeconds: 0)
        #expect(explosive > 0.5, "expected a fast launch, got \(explosive)")

        // ...and strictly faster than a controlled lift at the same point.
        #expect(explosive > easing(1.0 / 3.0, driveSeconds: 3))
    }

    /// Explosiveness should scale smoothly with the prescribed duration,
    /// not flip between two modes.
    @Test func explosivenessDecreasesWithLongerDrives() {
        let quarterWay = 0.25
        let values = [0.0, 0.5, 1.0, 1.5, 2.0].map {
            easing(quarterWay, driveSeconds: $0)
        }
        for (a, b) in zip(values, values.dropFirst()) {
            #expect(a >= b, "a longer drive should not launch harder")
        }
    }

    // MARK: - Whole-second stepping

    /// Mirrors the stepper arithmetic in `CustomTempoView.PhaseRow`, the
    /// only place a tempo value can now be changed.
    private func stepUp(_ v: Double) -> Double { min(9, v.rounded(.down) + 1) }
    private func stepDown(_ v: Double) -> Double { max(0, v.rounded(.up) - 1) }

    /// Tempo values are whole seconds only. Stepping from *any* starting
    /// point — including a legacy half-second value saved before the rule
    /// changed — must land on a whole number inside 0...9.
    @Test(arguments: [0.0, 0.5, 1.0, 1.5, 3.0, 8.0, 8.5, 9.0])
    func steppingAlwaysYieldsWholeSecondsInRange(start: Double) {
        for result in [stepUp(start), stepDown(start)] {
            #expect(result == result.rounded(), "\(start) produced \(result)")
            #expect(result >= 0 && result <= 9)
            // A negative zero would render as "-0" in the digit box.
            #expect(!(result == 0 && result.sign == .minus))
        }
    }

    /// A legacy 1.5 should resolve to a neighbouring whole second rather
    /// than being preserved or jumping two steps.
    @Test func legacyHalfSecondSnapsToWholeSeconds() {
        #expect(stepUp(1.5) == 2)
        #expect(stepDown(1.5) == 1)
    }

    // MARK: - Position mapping

    /// Mirrors `TempoPacingView.position`. 0 = top of track, 1 = bottom.
    private func position(phase: Phase, progress: Double, reversed: Bool,
                          driveSeconds: Double = 1) -> Double {
        let anatomical: Double
        switch phase {
        case .eccentric: anatomical = progress
        case .pauseBottom: anatomical = 1
        case .concentric: anatomical = 1 - easing(progress, driveSeconds: driveSeconds)
        case .pauseTop: anatomical = 0
        default: anatomical = 0
        }
        return reversed ? 1 - anatomical : anatomical
    }

    @Test func controlDescendsAndDriveReturns() {
        #expect(position(phase: .eccentric, progress: 0, reversed: false) == 0)
        #expect(position(phase: .eccentric, progress: 1, reversed: false) == 1)
        #expect(abs(position(phase: .concentric, progress: 0, reversed: false) - 1) < 1e-9)
        #expect(abs(position(phase: .concentric, progress: 1, reversed: false)) < 1e-9)
    }

    @Test func isometricHoldsSitAtOppositeEnds() {
        #expect(position(phase: .pauseBottom, progress: 0.5, reversed: false) == 1)
        #expect(position(phase: .pauseTop, progress: 0.5, reversed: false) == 0)
    }

    /// Reverse Direction mirrors the whole track — for a lat pulldown the
    /// stretched position is the top of the movement, not the bottom.
    @Test func reverseDirectionMirrorsEveryPhase() {
        let cases: [(Phase, Double)] = [
            (.eccentric, 0), (.eccentric, 0.5), (.eccentric, 1),
            (.pauseBottom, 0.5), (.concentric, 0.5), (.pauseTop, 0.5),
        ]
        for (phase, progress) in cases {
            let normal = position(phase: phase, progress: progress, reversed: false)
            let reversed = position(phase: phase, progress: progress, reversed: true)
            #expect(abs((normal + reversed) - 1) < 1e-9,
                    "\(phase) at \(progress) should mirror, got \(normal)/\(reversed)")
        }
    }

    /// The end of the eccentric and the start of the concentric must land
    /// on the same point, or the dot visibly jumps at the phase boundary —
    /// including across the bottom hold between them.
    @Test func phaseBoundariesLineUpWithNoJump() {
        for reversed in [false, true] {
            let endOfEccentric = position(phase: .eccentric, progress: 1, reversed: reversed)
            let hold = position(phase: .pauseBottom, progress: 0, reversed: reversed)
            let startOfConcentric = position(phase: .concentric, progress: 0, reversed: reversed)
            #expect(abs(endOfEccentric - hold) < 1e-9)
            #expect(abs(hold - startOfConcentric) < 1e-9)

            let endOfConcentric = position(phase: .concentric, progress: 1, reversed: reversed)
            let topHold = position(phase: .pauseTop, progress: 0, reversed: reversed)
            // And back round to the next rep's eccentric.
            let nextEccentric = position(phase: .eccentric, progress: 0, reversed: reversed)
            #expect(abs(endOfConcentric - topHold) < 1e-9)
            #expect(abs(topHold - nextEccentric) < 1e-9)
        }
    }
}
