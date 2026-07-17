import AVFoundation
import Observation

/// Lets the user pick a specific installed text-to-speech voice per
/// language, instead of always using whichever AVSpeechSynthesisVoice iOS
/// considers the default. Persisted as language-code -> voice-identifier
/// pairs, so a choice made for English doesn't affect Dutch, French, or
/// German.
@MainActor
@Observable
final class VoicePreferenceStore {
    static let shared = VoicePreferenceStore()

    private static let defaultsKey = "voiceIdentifierOverrides"

    private var overridesByLanguage: [String: String]

    private init() {
        overridesByLanguage = UserDefaults.standard.dictionary(forKey: Self.defaultsKey) as? [String: String] ?? [:]
    }

    /// Every installed voice that can speak the given BCP-47 language code,
    /// matched by primary subtag (e.g. "en") so British/Australian/Irish
    /// English voices all show up as options for the app's English cues —
    /// the spoken words don't change, just the accent.
    func availableVoices(for languageCode: String) -> [AVSpeechSynthesisVoice] {
        guard let base = Locale(identifier: languageCode).language.languageCode?.identifier else { return [] }
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { Locale(identifier: $0.language).language.languageCode?.identifier == base }
            .sorted { $0.name < $1.name }
    }

    func voiceIdentifier(for languageCode: String) -> String? {
        overridesByLanguage[languageCode]
    }

    func setVoiceIdentifier(_ identifier: String?, for languageCode: String) {
        if let identifier {
            overridesByLanguage[languageCode] = identifier
        } else {
            overridesByLanguage.removeValue(forKey: languageCode)
        }
        UserDefaults.standard.set(overridesByLanguage, forKey: Self.defaultsKey)
    }
}
