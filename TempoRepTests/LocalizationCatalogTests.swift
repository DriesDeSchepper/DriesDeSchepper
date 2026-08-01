import Testing
import Foundation
@testable import TempoRep

/// Guards against a key existing in only some of the app's 4 languages, and
/// against `L()`'s per-language Bundle lookup regressing to always
/// returning English (exactly the bug this suite caught during development).
struct LocalizationCatalogTests {

    @Test(arguments: ["en", "nl", "fr", "de"])
    func keyUIStringsResolvePerLanguage(languageCode: String) {
        let locale = Locale(identifier: languageCode)
        let resolved = [
            L("Exercise", locale),
            L("No exercise selected", locale),
            L("Start with", locale),
            L("Tempo details", locale),
            L("Eccentric", locale),
            L("Concentric", locale),
            L("Bilateral", locale),
            L("Unilateral", locale),
            L("Left", locale),
            L("Right", locale),
            L("Presets", locale),
            L("Save Preset", locale),
            L("Preset name", locale),
            L("Cancel", locale),
            L("Save", locale),
            L("Delete", locale),
            L("Close", locale),
            L("Voice", locale),
            L("Voice countdown", locale),
            L("Speech voice", locale),
            L("Automatic", locale),
            L("Enhanced", locale),
            L("Premium", locale),
            L("Custom Tempo", locale),
            L("Seconds per phase", locale),
            L("Bottom Pause", locale),
            L("Top Pause", locale),
            L("Rep direction", locale),
            L("Reverse Direction", locale),
            L("Recommended", locale),
            L("tempo.control", locale),
            L("tempo.hold", locale),
            L("tempo.drive", locale),
            L("phase.concentric.title", locale),
            L("phase.pause.title", locale),
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

    /// The rep-phase cues were renamed away from direction words
    /// (Down/Up), which are wrong on any exercise using Reverse Direction.
    @Test func repPhaseVoiceCuesAreDirectionAgnostic() {
        for code in ["en", "nl", "fr", "de"] {
            let locale = Locale(identifier: code)
            let control = L("phase.eccentric.voice", locale)
            let drive = L("phase.concentric.voice", locale)
            #expect(!control.isEmpty && !drive.isEmpty)
            #expect(control != drive, "control and drive must not collide in \(code)")
        }
        #expect(L("phase.eccentric.voice", Locale(identifier: "en")) == "Control")
        #expect(L("phase.concentric.voice", Locale(identifier: "en")) == "Drive")
        #expect(L("phase.pause.voice", Locale(identifier: "en")) == "Hold")
    }

    @Test func switchSidesVoiceMatchesSpecifiedPhrasing() {
        #expect(L("phase.switchSides.voice", Locale(identifier: "en")) == "Switch side")
        #expect(L("phase.switchSides.voice", Locale(identifier: "nl")) == "Wissel van kant")
        #expect(L("phase.switchSides.voice", Locale(identifier: "fr")) == "Change de côté")
        #expect(L("phase.switchSides.voice", Locale(identifier: "de")) == "Seitenwechsel")
    }
}
