import SwiftUI
import AVFoundation

/// A plain, native `Form` — no custom backgrounds or row colors. Settings
/// screens are exactly what `Form` is for; letting it use the system's own
/// grouped-list materials means it adapts to light/dark automatically and
/// picks up future OS styling (Liquid Glass and beyond) for free.
struct SettingsView: View {
    @Bindable var engine: WorkoutEngine
    @Environment(\.dismiss) private var dismiss
    private let localization = LocalizationManager.shared
    private let voicePreferences = VoicePreferenceStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: Binding(
                        get: { localization.override },
                        set: { localization.override = $0 }
                    )) {
                        Text("System").tag(LocalizationManager.Language?.none)
                        ForEach(LocalizationManager.Language.allCases) { language in
                            // A language's own name is never translated —
                            // "Nederlands" reads the same no matter which
                            // language the rest of the app is displayed in.
                            Text(verbatim: language.displayName).tag(Optional(language))
                        }
                    } label: {
                        Text("Language")
                    }
                    .sensoryFeedback(.selection, trigger: localization.override)
                } header: {
                    Text("Language")
                }

                Section {
                    Toggle("Voice countdown", isOn: $engine.config.voiceCues)
                        .tint(Color.accentColor)
                        .sensoryFeedback(.selection, trigger: engine.config.voiceCues)

                    Picker(selection: Binding(
                        get: { voicePreferences.voiceIdentifier(for: speechLanguageCode) },
                        set: { selectVoice($0) }
                    )) {
                        Text("Automatic").tag(String?.none)
                        ForEach(availableVoices, id: \.identifier) { voice in
                            Text(verbatim: voiceLabel(voice)).tag(Optional(voice.identifier))
                        }
                    } label: {
                        Text("Speech voice")
                    }
                    .sensoryFeedback(.selection, trigger: voicePreferences.voiceIdentifier(for: speechLanguageCode))
                } header: {
                    Text("Voice")
                } footer: {
                    // Picking a voice speaks a short sample immediately, so
                    // there's no need to spell out what each one sounds like.
                    Text("Shows voices for the app's current language, set above.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
        }
        .tint(Color.accentColor)
    }

    private var speechLanguageCode: String {
        localization.language.speechLanguageCode
    }

    private var availableVoices: [AVSpeechSynthesisVoice] {
        voicePreferences.availableVoices(for: speechLanguageCode)
    }

    private func selectVoice(_ identifier: String?) {
        voicePreferences.setVoiceIdentifier(identifier, for: speechLanguageCode)
        engine.previewVoice(languageCode: speechLanguageCode,
                             sampleText: L("phase.eccentric.voice", localization.locale))
    }

    private func voiceLabel(_ voice: AVSpeechSynthesisVoice) -> String {
        switch voice.quality {
        case .enhanced: return "\(voice.name) (\(L("Enhanced", localization.locale)))"
        case .premium: return "\(voice.name) (\(L("Premium", localization.locale)))"
        default: return voice.name
        }
    }
}

#Preview {
    SettingsView(engine: WorkoutEngine())
}
