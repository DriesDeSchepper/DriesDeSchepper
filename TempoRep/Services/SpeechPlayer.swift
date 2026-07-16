import AVFoundation

/// Speaks short workout cues ("Down", "Hold", "Up", rep numbers, countdowns)
/// via AVSpeechSynthesizer. Uses the app's shared audio session, so speech
/// mixes over the user's music just like the beep cues.
final class SpeechPlayer {
    private let synthesizer = AVSpeechSynthesizer()
    private let voice = AVSpeechSynthesisVoice(language: "en-US")

    func speak(_ text: String) {
        // Cancel anything still in flight so fast tempos never build a backlog.
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.52
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
