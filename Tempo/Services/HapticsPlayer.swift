import UIKit

/// Distinct haptic cues for phase changes, rep completion, and set completion.
@MainActor
final class HapticsPlayer {
    private let phaseImpact = UIImpactFeedbackGenerator(style: .medium)
    private let repImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()

    func prepare() {
        phaseImpact.prepare()
        repImpact.prepare()
        notification.prepare()
    }

    func phaseChange() {
        phaseImpact.impactOccurred()
        phaseImpact.prepare()
    }

    func repComplete() {
        repImpact.impactOccurred(intensity: 1.0)
        repImpact.prepare()
    }

    func setComplete() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }
}
