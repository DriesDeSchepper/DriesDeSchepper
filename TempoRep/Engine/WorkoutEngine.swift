import Foundation
import Observation
import UIKit

/// Drives a workout. The full workout is precomputed into a flat timeline of
/// segments, and the current state is always derived from wall-clock elapsed
/// time (minus paused time) — the repeating Timer only samples, so the
/// countdown can never drift no matter how late individual ticks fire.
@MainActor
@Observable
final class WorkoutEngine {
    enum State: Equatable {
        case idle
        case running
        case paused
        case finished
    }

    var config = WorkoutConfig()

    private(set) var state: State = .idle
    private(set) var currentPhase: Phase = .getReady
    private(set) var currentRep = 0
    private(set) var currentSet = 1
    private(set) var phaseRemaining: TimeInterval = 0
    private(set) var phaseProgress: Double = 0 // 0...1 within the current segment

    @ObservationIgnored private var timeline: [Segment] = []
    @ObservationIgnored private var startDate = Date()
    @ObservationIgnored private var pausedAccumulated: TimeInterval = 0
    @ObservationIgnored private var pauseBegan: Date?
    @ObservationIgnored private var segmentIndex = -1
    @ObservationIgnored private var lastSpokenCountdown = -1
    @ObservationIgnored private var ticker: Timer?

    private let sound = SoundPlayer()
    private let haptics = HapticsPlayer()
    private let speech = SpeechPlayer()

    // MARK: - Controls

    func start() {
        timeline = Self.buildTimeline(for: config)
        guard !timeline.isEmpty else { return }
        startDate = Date()
        pausedAccumulated = 0
        pauseBegan = nil
        segmentIndex = -1
        currentRep = 0
        currentSet = 1
        state = .running
        sound.activateSession()
        sound.startKeepAlive()
        haptics.prepare()
        UIApplication.shared.isIdleTimerDisabled = true
        startTicker()
        tick()
    }

    func pause() {
        guard state == .running else { return }
        pauseBegan = Date()
        state = .paused
        stopTicker()
    }

    func resume() {
        guard state == .paused else { return }
        if let pauseBegan {
            pausedAccumulated += Date().timeIntervalSince(pauseBegan)
        }
        pauseBegan = nil
        state = .running
        startTicker()
        tick()
    }

    func stop() {
        stopTicker()
        UIApplication.shared.isIdleTimerDisabled = false
        speech.stop()
        sound.stopKeepAlive()
        sound.deactivateSession()
        state = .idle
    }

    // MARK: - Timeline

    static func buildTimeline(for config: WorkoutConfig) -> [Segment] {
        var segments: [Segment] = []
        var cursor: TimeInterval = 0

        func add(_ phase: Phase, rep: Int, set: Int, seconds: TimeInterval) {
            guard seconds > 0 else { return } // zero-length phases are skipped entirely
            segments.append(Segment(phase: phase, rep: rep, set: set, start: cursor, duration: seconds))
            cursor += seconds
        }

        add(.getReady, rep: 0, set: 1, seconds: 3)

        for set in 1...config.sets {
            for rep in 1...config.repsPerSet {
                add(.eccentric, rep: rep, set: set, seconds: TimeInterval(config.tempoDigits[0]))
                add(.pauseBottom, rep: rep, set: set, seconds: TimeInterval(config.tempoDigits[1]))
                add(.concentric, rep: rep, set: set, seconds: TimeInterval(config.concentricSeconds))
                add(.pauseTop, rep: rep, set: set, seconds: TimeInterval(config.tempoDigits[3]))
            }
            if set < config.sets {
                add(.rest, rep: 0, set: set, seconds: TimeInterval(config.restSeconds))
            }
        }
        return segments
    }

    static func estimatedDuration(for config: WorkoutConfig) -> TimeInterval {
        buildTimeline(for: config).last?.end ?? 0
    }

    // MARK: - Tick

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        timer.tolerance = 0.005
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    private func tick() {
        guard state == .running else { return }
        let elapsed = Date().timeIntervalSince(startDate) - pausedAccumulated

        guard let index = timeline.firstIndex(where: { elapsed < $0.end }) else {
            finish()
            return
        }

        if index != segmentIndex {
            playCues(enteringIndex: index)
            segmentIndex = index
            lastSpokenCountdown = -1
        }

        let segment = timeline[index]
        currentPhase = segment.phase
        if segment.rep > 0 { currentRep = segment.rep }
        currentSet = segment.set
        phaseRemaining = segment.end - elapsed
        phaseProgress = min(1, max(0, (elapsed - segment.start) / segment.duration))

        // Spoken 3-2-1 lead-in during get-ready and at the end of each rest.
        if config.voiceCues, segment.phase == .rest || segment.phase == .getReady {
            let secondsLeft = Int(phaseRemaining.rounded(.up))
            if secondsLeft <= 3, secondsLeft >= 1, secondsLeft != lastSpokenCountdown {
                speech.speak("\(secondsLeft)")
                lastSpokenCountdown = secondsLeft
            }
        }
    }

    private func finish() {
        guard state == .running else { return }
        stopTicker()
        state = .finished
        currentPhase = .done
        phaseRemaining = 0
        phaseProgress = 1
        UIApplication.shared.isIdleTimerDisabled = false
        sound.stopKeepAlive()
        sound.play(.workoutComplete)
        haptics.setComplete()
        if config.voiceCues {
            speech.speak(Phase.done.voiceWord)
        }
    }

    // MARK: - Cues

    private func playCues(enteringIndex index: Int) {
        // With voice on, speech replaces the phase/rep beeps (haptics and the
        // set/finish chimes stay); with voice off, behavior is unchanged.
        let voice = config.voiceCues

        guard index > 0 else {
            haptics.phaseChange()
            if !voice {
                sound.play(.phaseChange)
            }
            // With voice on, the spoken 3-2-1 covers the get-ready lead-in.
            return
        }
        let old = timeline[index - 1]
        let new = timeline[index]

        if new.phase == .rest {
            // Last rep of the set just finished.
            sound.play(.setComplete)
            haptics.setComplete()
            if voice {
                speech.speak(Phase.rest.voiceWord)
            }
        } else if old.phase == .rest || old.phase == .getReady {
            // A new set (or the workout) is starting.
            haptics.phaseChange()
            if voice {
                speech.speak(new.phase.voiceWord)
            } else {
                sound.play(.phaseChange)
            }
        } else if old.rep != new.rep {
            // Crossed a rep boundary within a set: speak the new rep number.
            haptics.repComplete()
            if voice {
                speech.speak("\(new.rep)")
            } else {
                sound.play(.repComplete)
            }
        } else {
            haptics.phaseChange()
            if voice {
                speech.speak(new.phase.voiceWord)
            } else {
                sound.play(.phaseChange)
            }
        }
    }
}
