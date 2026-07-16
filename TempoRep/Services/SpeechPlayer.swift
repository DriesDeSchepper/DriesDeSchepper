import AVFoundation

/// Speaks short workout cues ("Down", "Hold", "Up", rep numbers, countdowns)
/// via AVSpeechSynthesizer, using a voice that matches the current language.
/// Uses the app's shared audio session, so speech mixes over the user's
/// music just like the beep cues. Plain digit strings (e.g. "3") are spoken
/// correctly in the target language by the voice itself — no per-language
/// number spelling is needed.
final class SpeechPlayer {
    private let synthesizer = AVSpeechSynthesizer()
    private var voiceCache: [String: AVSpeechSynthesisVoice] = [:]

    func speak(_ text: String, languageCode: String) {
        // Cancel anything still in flight so fast tempos never build a backlog.
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(for: languageCode)
        utterance.rate = 0.52
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func voice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        if let cached = voiceCache[languageCode] { return cached }
        let voice = AVSpeechSynthesisVoice(language: languageCode)
        voiceCache[languageCode] = voice
        return voice
    }
}
