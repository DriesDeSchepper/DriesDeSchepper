import Testing
@testable import TempoRep

@MainActor
struct VoicePreferenceStoreTests {

    @Test func voiceIdentifierRoundTripsAndClearsWithNil() {
        let store = VoicePreferenceStore.shared
        let languageCode = "en-US"
        let original = store.voiceIdentifier(for: languageCode)
        defer { store.setVoiceIdentifier(original, for: languageCode) }

        store.setVoiceIdentifier("com.apple.voice.test-identifier", for: languageCode)
        #expect(store.voiceIdentifier(for: languageCode) == "com.apple.voice.test-identifier")

        store.setVoiceIdentifier(nil, for: languageCode)
        #expect(store.voiceIdentifier(for: languageCode) == nil)
    }

    @Test func overridesAreScopedPerLanguage() {
        let store = VoicePreferenceStore.shared
        let en = store.voiceIdentifier(for: "en-US")
        let nl = store.voiceIdentifier(for: "nl-NL")
        defer {
            store.setVoiceIdentifier(en, for: "en-US")
            store.setVoiceIdentifier(nl, for: "nl-NL")
        }

        store.setVoiceIdentifier("en-choice", for: "en-US")
        store.setVoiceIdentifier("nl-choice", for: "nl-NL")

        #expect(store.voiceIdentifier(for: "en-US") == "en-choice")
        #expect(store.voiceIdentifier(for: "nl-NL") == "nl-choice")
    }

    @Test func availableVoicesMatchByPrimaryLanguageSubtag() {
        let store = VoicePreferenceStore.shared
        let voices = store.availableVoices(for: "en-US")
        #expect(!voices.isEmpty)
        #expect(voices.allSatisfy { $0.language.hasPrefix("en") })
    }
}
