import Foundation
import Observation

/// Resolves a catalog key to a string in an explicit locale. Used anywhere
/// outside a SwiftUI `Text` (which localizes via `\.locale` in the
/// environment automatically): voice cues, and any hand-formatted string.
///
/// Loads the target language's compiled `.lproj` bundle directly rather
/// than using `String(localized:locale:)` — in testing, that call
/// consistently returned the English value regardless of the `locale`
/// argument, so this uses the classic, unambiguous `Bundle` API instead.
func L(_ key: String, _ locale: Locale) -> String {
    let languageCode = locale.language.languageCode?.identifier ?? locale.identifier
    guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
          let bundle = Bundle(path: path) else {
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
    return bundle.localizedString(forKey: key, value: nil, table: nil)
}

/// Tracks the app's language: nil follows the iOS system language: a
/// non-nil value overrides it. The effective locale is applied to SwiftUI
/// text via `.environment(\.locale, ...)` at the root; non-View code (voice
/// cues, date formatting) reads `language`/`locale` directly since it has
/// no environment to inherit from.
@MainActor
@Observable
final class LocalizationManager {
    static let shared = LocalizationManager()

    enum Language: String, CaseIterable, Identifiable, Codable {
        case en, nl, fr, de
        var id: String { rawValue }

        /// BCP-47 tag used to pick a matching AVSpeechSynthesisVoice.
        var speechLanguageCode: String {
            switch self {
            case .en: return "en-US"
            case .nl: return "nl-NL"
            case .fr: return "fr-FR"
            case .de: return "de-DE"
            }
        }

        /// The language's own name, in its own script — never run through
        /// the app's translation catalog (it doesn't change with UI language).
        var displayName: String {
            switch self {
            case .en: return "English"
            case .nl: return "Nederlands"
            case .fr: return "Français"
            case .de: return "Deutsch"
            }
        }
    }

    private static let defaultsKey = "languageOverride"

    var override: Language? {
        didSet {
            UserDefaults.standard.set(override?.rawValue, forKey: Self.defaultsKey)
        }
    }

    init() {
        override = UserDefaults.standard.string(forKey: Self.defaultsKey).flatMap(Language.init)
    }

    /// The effective language: the override if set, else the first of the
    /// system's preferred languages that this app supports, else English.
    var language: Language {
        if let override { return override }
        for preferred in Locale.preferredLanguages {
            let base = Locale(identifier: preferred).language.languageCode?.identifier
            if let base, let match = Language(rawValue: base) {
                return match
            }
        }
        return .en
    }

    var locale: Locale {
        Locale(identifier: language.rawValue)
    }
}
