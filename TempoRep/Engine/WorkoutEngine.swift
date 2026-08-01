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

    var config = WorkoutConfig.loadSaved() {
        didSet { config.save() }
    }

    let history = HistoryStore()
    let presets = PresetStore()

    private(set) var state: State = .idle
    private(set) var currentPhase: Phase = .getReady
    private(set) var currentRep = 0
    private(set) var currentSet = 1
    private(set) var currentSide: Side?
    private(set) var phaseRemaining: TimeInterval = 0
    private(set) var phaseProgress: Double = 0 // 0...1 within the current segment
    private(set) var lastTimeUnderTension: TimeInterval = 0
    /// The exercise that was just completed, captured at finish so the
    /// summary keeps showing it even if the selection changes afterwards.
    private(set) var lastExerciseName: String?

    @ObservationIgnored private var timeline: [Segment] = []
    @ObservationIgnored private var startDate = Date()
    @ObservationIgnored private var pausedAccumulated: TimeInterval = 0
    @ObservationIgnored private var pauseBegan: Date?
    @ObservationIgnored private var segmentIndex = -1
    @ObservationIgnored private var lastSpokenCountdown = -1
    @ObservationIgnored private var lastSpokenSecondInSegment = -1
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

    /// Speaks a short sample outside of a workout, so Settings can let the
    /// user hear a candidate voice before committing to it.
    func previewVoice(languageCode: String, sampleText: String) {
        speech.speak(sampleText, languageCode: languageCode)
    }

    // MARK: - Timeline

    static func buildTimeline(for config: WorkoutConfig) -> [Segment] {
        var segments: [Segment] = []
        var cursor: TimeInterval = 0

        func add(_ phase: Phase, rep: Int, set: Int, side: Side?, seconds: TimeInterval) {
            guard seconds > 0 else { return } // zero-length phases are skipped entirely
            segments.append(Segment(phase: phase, rep: rep, set: set, side: side, start: cursor, duration: seconds))
            cursor += seconds
        }

        // A rep's 4 tempo phases in execution order. The digits keep their
        // usual meaning either way — only which phase leads changes, for
        // exercises (deadlifts, pull-ups) that start by lifting.
        func phaseSeconds(_ phase: Phase) -> TimeInterval {
            switch phase {
            case .eccentric: return TimeInterval(config.tempoDigits[0])
            case .pauseBottom: return TimeInterval(config.tempoDigits[1])
            case .concentric: return TimeInterval(config.concentricSeconds)
            case .pauseTop: return TimeInterval(config.tempoDigits[3])
            default: return 0
            }
        }
        let repPhaseOrder: [Phase] = config.startPhase == .concentric
            ? [.concentric, .pauseTop, .eccentric, .pauseBottom]
            : [.eccentric, .pauseBottom, .concentric, .pauseTop]

        add(.getReady, rep: 0, set: 1, side: nil, seconds: 3)

        // Bilateral work has one (sideless) pass per set; unilateral work
        // does the full rep count for the starting side, then (after an
        // optional switch pause) the full rep count for the other side —
        // both within the same set, before any between-sets rest.
        let sides: [Side?] = config.unilateral ? [config.startingSide, config.startingSide.opposite] : [nil]

        for set in 1...config.sets {
            for (sideIndex, side) in sides.enumerated() {
                for rep in 1...config.repsPerSet {
                    for phase in repPhaseOrder {
                        add(phase, rep: rep, set: set, side: side, seconds: phaseSeconds(phase))
                    }
                }
                let isLastSide = sideIndex == sides.count - 1
                if !isLastSide, let nextSide = side?.opposite {
                    // The upcoming side is attached to the segment itself so
                    // the UI can show "up next: Right" during the pause.
                    add(.switchSides, rep: 0, set: set, side: nextSide, seconds: TimeInterval(config.switchSeconds))
                }
            }
            if set < config.sets {
                add(.rest, rep: 0, set: set, side: nil, seconds: TimeInterval(config.restSeconds))
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
            lastSpokenSecondInSegment = -1
        }

        let segment = timeline[index]
        currentPhase = segment.phase
        if segment.rep > 0 { currentRep = segment.rep }
        currentSet = segment.set
        currentSide = segment.side
        phaseRemaining = segment.end - elapsed
        phaseProgress = min(1, max(0, (elapsed - segment.start) / segment.duration))

        guard config.voiceCues else { return }
        let languageCode = LocalizationManager.shared.language.speechLanguageCode

        // Spoken 3-2-1 lead-in during get-ready and at the end of each rest.
        // A switch-side pause only gets the countdown when it's long enough
        // (4s+) to be worth counting down — shorter ones just get the
        // "Switch side" announcement spoken once, in playCues.
        if segment.phase == .rest || segment.phase == .getReady
            || (segment.phase == .switchSides && segment.duration >= 4) {
            let secondsLeft = Int(phaseRemaining.rounded(.up))
            if secondsLeft <= 3, secondsLeft >= 1, secondsLeft != lastSpokenCountdown {
                speech.speak("\(secondsLeft)", languageCode: languageCode)
                lastSpokenCountdown = secondsLeft
            }
        } else if segment.rep > 0, segment.duration > 1 {
            // In-rep phases (eccentric/hold/concentric) longer than a second
            // are counted up as they happen: the phase word covers second 1
            // (spoken once on entry in playCues), then "2", "3", ... follow
            // once per elapsed second — e.g. a 4s eccentric speaks
            // "Down, 2, 3, 4".
            let secondInSegment = Int(elapsed - segment.start) + 1
            if secondInSegment >= 2, secondInSegment <= Int(segment.duration), secondInSegment != lastSpokenSecondInSegment {
                speech.speak("\(secondInSegment)", languageCode: languageCode)
                lastSpokenSecondInSegment = secondInSegment
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
            let locale = LocalizationManager.shared.locale
            speech.speak(Phase.done.voiceWord(locale), languageCode: LocalizationManager.shared.language.speechLanguageCode)
        }
        // Both sides' reps count, and — for a unilateral workout — the
        // switch pause between them, since it's part of the set rather than
        // rest between sets.
        let timeUnderTension = timeline.filter { $0.rep > 0 || $0.phase == .switchSides }.reduce(0) { $0 + $1.duration }
        lastTimeUnderTension = timeUnderTension
        lastExerciseName = ExerciseDatabase.shared.exercise(id: config.selectedExerciseID)?.name

        history.add(WorkoutRecord(
            id: UUID(),
            date: Date(),
            exerciseName: ExerciseDatabase.shared.exercise(id: config.selectedExerciseID)?.name,
            tempoDigits: config.tempoDigits,
            sets: config.sets,
            repsPerSet: config.repsPerSet,
            restSeconds: config.restSeconds,
            timeUnderTension: timeUnderTension,
            totalDuration: timeline.last?.end ?? 0
        ))
    }

    // MARK: - Cues

    private func playCues(enteringIndex index: Int) {
        // With voice on, speech replaces the phase/rep beeps (haptics and the
        // set/finish chimes stay); with voice off, behavior is unchanged.
        let voice = config.voiceCues
        let locale = LocalizationManager.shared.locale
        let languageCode = LocalizationManager.shared.language.speechLanguageCode

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
                speech.speak(Phase.rest.voiceWord(locale), languageCode: languageCode)
            }
        } else if new.phase == .switchSides {
            // Finished all reps for one side; pausing (or moving straight on,
            // if switch time is 0) before starting the other side.
            haptics.setComplete()
            if voice {
                speech.speak(Phase.switchSides.voiceWord(locale), languageCode: languageCode)
            } else {
                sound.play(.sideSwitch)
            }
        } else if old.phase == .rest || old.phase == .getReady || old.phase == .switchSides {
            // A new set, a new side, or the workout itself is starting.
            haptics.phaseChange()
            if voice {
                speech.speak(new.phase.voiceWord(locale, reversed: config.reverseDirection), languageCode: languageCode)
            } else {
                sound.play(.phaseChange)
            }
        } else {
            // Any other phase change, including rep boundaries (a new rep
            // always starts with the eccentric phase). Haptics distinguish a
            // rep boundary from a within-rep phase change, but the voice cue
            // is always the phase word, so the "Down, 2, 3, 4" style count
            // (see tick()) stays unambiguous on every rep — a spoken rep
            // number here would collide with that per-second count.
            let crossedRep = old.rep != new.rep
            if crossedRep {
                haptics.repComplete()
            } else {
                haptics.phaseChange()
            }
            if voice {
                speech.speak(new.phase.voiceWord(locale, reversed: config.reverseDirection), languageCode: languageCode)
            } else {
                sound.play(crossedRep ? .repComplete : .phaseChange)
            }
        }
    }
}
