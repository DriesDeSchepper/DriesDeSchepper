import Testing
import Foundation
@testable import TempoRep

/// Guards against a key existing in only some of the app's 4 languages —
/// every call here is a literal (not a dynamic string), since
/// `String.LocalizationValue` resolves from source literals.
struct LocalizationCatalogTests {

    @Test(arguments: ["en", "nl", "fr", "de"])
    func keyUIStringsResolvePerLanguage(languageCode: String) {
        let locale = Locale(identifier: languageCode)
        let resolved = [
            L("Exercise", locale),
            L("No exercise selected", locale),
            L("Starts with", locale),
            L("Eccentric", locale),
            L("Concentric", locale),
            L("Bilateral", locale),
            L("Unilateral", locale),
            L("Left", locale),
            L("Right", locale),
            L("My Presets", locale),
            L("Save Preset", locale),
            L("Preset name", locale),
            L("Cancel", locale),
            L("Save", locale),
            L("Delete", locale),
            L("phase.getReady.title", locale),
            L("phase.eccentric.voice", locale),
            L("phase.pause.voice", locale),
            L("phase.concentric.voice", locale),
            L("phase.rest.voice", locale),
            L("phase.switchSides.voice", locale),
            L("phase.done.voice", locale),
        ]
        #expect(resolved.allSatisfy { $0.isEmpty == false })
    }

    @Test func voiceCuePhrasesAreDistinctPerLanguage() {
        let words = ["en", "nl", "fr", "de"].map { L("phase.eccentric.voice", Locale(identifier: $0)) }
        #expect(Set(words).count == 4, "expected 4 distinct translations, got \(words)")
    }

    @Test func switchSidesVoiceMatchesSpecifiedPhrasing() {
        #expect(L("phase.switchSides.voice", Locale(identifier: "en")) == "Switch side")
        #expect(L("phase.switchSides.voice", Locale(identifier: "nl")) == "Wissel van kant")
        #expect(L("phase.switchSides.voice", Locale(identifier: "fr")) == "Change de côté")
        #expect(L("phase.switchSides.voice", Locale(identifier: "de")) == "Seitenwechsel")
    }
}
