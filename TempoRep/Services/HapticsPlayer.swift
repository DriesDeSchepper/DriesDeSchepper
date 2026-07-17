import CoreHaptics
import UIKit

/// Distinct haptic cues for phase changes, rep completion, and set
/// completion — a single sharp tap, a quick double-tap, and a three-tap
/// ascending pattern respectively, built with Core Haptics so each event is
/// genuinely distinguishable by feel alone, not just by impact style.
/// Devices without a Taptic Engine capable of custom patterns (some iPads,
/// older iPhones) fall back to the plain `UIImpactFeedbackGenerator`/
/// `UINotificationFeedbackGenerator` cues this used before.
@MainActor
final class HapticsPlayer {
    private let supportsCustomHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?

    private let phaseImpact = UIImpactFeedbackGenerator(style: .medium)
    private let repImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    init() {
        guard supportsCustomHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak engine] in
            try? engine?.start()
        }
        // Nothing to do on stop — the next cue's `play(events:)` restarts
        // the engine on demand.
        engine?.stoppedHandler = { _ in }
    }

    func prepare() {
        if supportsCustomHaptics {
            try? engine?.start()
        } else {
            phaseImpact.prepare()
            repImpact.prepare()
            notification.prepare()
        }
    }

    func phaseChange() {
        play([Self.tap(at: 0, intensity: 0.75, sharpness: 0.7)]) {
            self.phaseImpact.impactOccurred()
            self.phaseImpact.prepare()
        }
    }

    func repComplete() {
        play([
            Self.tap(at: 0, intensity: 0.85, sharpness: 0.9),
            Self.tap(at: 0.09, intensity: 0.85, sharpness: 0.9),
        ]) {
            self.repImpact.impactOccurred(intensity: 1.0)
            self.repImpact.prepare()
        }
    }

    func setComplete() {
        play([
            Self.tap(at: 0, intensity: 0.6, sharpness: 0.5),
            Self.tap(at: 0.12, intensity: 0.8, sharpness: 0.6),
            Self.tap(at: 0.24, intensity: 1.0, sharpness: 0.8),
        ]) {
            self.notification.notificationOccurred(.success)
            self.notification.prepare()
        }
    }

    private func play(_ events: [CHHapticEvent], fallback: () -> Void) {
        guard supportsCustomHaptics, let engine else {
            fallback()
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallback()
        }
    }

    private static func tap(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: time)
    }
}
