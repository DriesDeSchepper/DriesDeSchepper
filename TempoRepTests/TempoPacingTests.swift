import Testing
import Foundation
@testable import TempoRep

/// The pacing track's *look* can only be judged on a device, but the
/// arithmetic behind it is testable — and it's the part that would make
/// the app lie about pacing if it were wrong. These mirror
/// `TempoPacingView`'s `concentricEasing` and position mapping.
struct TempoPacingTests {

    // MARK: - Easing

    /// Mirrors `TempoPacingView.concentricEasing`.
    private func easing(_ progress: Double, concentricSeconds: Double) -> Double {
        let threshold = TempoMetrics.Pacing.explosiveThresholdSeconds
        let explosiveness = max(0, min(1, (threshold - concentricSeconds) / threshold))
        let easedOut = 1 - pow(1 - progress, 3)
        return progress + explosiveness * (easedOut - progress)
    }

    /// The whole point of easing rather than springing: however aggressive
    /// the curve, the dot must start at the bottom and arrive at the top
    /// exactly as the phase ends. Any drift here means the visual finishes
    /// early or late against the spoken cue.
    @Test(arguments: [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0])
    func easingAlwaysSpansTheFullPhase(concentricSeconds: Double) {
        #expect(easing(0, concentricSeconds: concentricSeconds) == 0)
        #expect(abs(easing(1, concentricSeconds: concentricSeconds) - 1) < 1e-9)
    }

    @Test(arguments: [0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0])
    func easingIsMonotonic(concentricSeconds: Double) {
        var previous = -1.0
        for step in 0...100 {
            let value = easing(Double(step) / 100, concentricSeconds: concentricSeconds)
            #expect(value >= previous, "went backwards at \(step)% for \(concentricSeconds)s")
            previous = value
        }
    }

    /// A controlled (2s+) concentric should track real time exactly — no
    /// ease-out at all, because a slow lift ought to look slow.
    @Test func controlledConcentricIsLinear() {
        for step in 0...10 {
            let p = Double(step) / 10
            #expect(abs(easing(p, concentricSeconds: 3) - p) < 1e-9)
        }
    }

    /// An explosive concentric should visibly launch: well past halfway
    /// by the time a third of the phase has elapsed.
    @Test func explosiveConcentricFrontLoadsTheTravel() {
        let explosive = easing(1.0 / 3.0, concentricSeconds: 0)
        #expect(explosive > 0.5, "expected a fast launch, got \(explosive)")

        // ...and strictly faster than a controlled lift at the same point.
        #expect(explosive > easing(1.0 / 3.0, concentricSeconds: 3))
    }

    /// Explosiveness should scale smoothly with the prescribed duration,
    /// not flip between two modes.
    @Test func explosivenessDecreasesWithLongerConcentrics() {
        let quarterWay = 0.25
        let values = [0.0, 0.5, 1.0, 1.5, 2.0].map {
            easing(quarterWay, concentricSeconds: $0)
        }
        for (a, b) in zip(values, values.dropFirst()) {
            #expect(a >= b, "a longer concentric should not launch harder")
        }
    }

    // MARK: - Position mapping

    /// Mirrors `TempoPacingView.position`. 0 = top of track, 1 = bottom.
    private func position(phase: Phase, progress: Double, reversed: Bool,
                          concentricSeconds: Double = 1) -> Double {
        let anatomical: Double
        switch phase {
        case .eccentric: anatomical = progress
        case .pauseBottom: anatomical = 1
        case .concentric: anatomical = 1 - easing(progress, concentricSeconds: concentricSeconds)
        case .pauseTop: anatomical = 0
        default: anatomical = 0
        }
        return reversed ? 1 - anatomical : anatomical
    }

    @Test func eccentricDescendsAndConcentricReturns() {
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
