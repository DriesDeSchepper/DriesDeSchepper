import SwiftUI

struct SettingsView: View {
    @Bindable var engine: WorkoutEngine
    @Environment(\.dismiss) private var dismiss
    private let localization = LocalizationManager.shared

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
                .listRowBackground(Color.white.opacity(0.06))

                Section {
                    Toggle("Voice countdown", isOn: $engine.config.voiceCues)
                        .tint(Color.accentColor)
                        .sensoryFeedback(.selection, trigger: engine.config.voiceCues)
                } header: {
                    Text("Voice")
                }
                .listRowBackground(Color.white.opacity(0.06))
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Color.accentColor)
    }
}

#Preview {
    SettingsView(engine: WorkoutEngine())
        .preferredColorScheme(.dark)
}
