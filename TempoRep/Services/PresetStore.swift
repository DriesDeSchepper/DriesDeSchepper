import Foundation
import Observation

/// Persists user-saved presets as JSON in UserDefaults, newest first. The
/// 4 built-in presets (`WorkoutPreset.builtIn`) live in code and are never
/// touched by this store.
@MainActor
@Observable
final class PresetStore {
    private(set) var custom: [WorkoutPreset] = []

    private static let defaultsKey = "customPresets"
    private static let maxPresets = 20

    init() {
        load()
    }

    func save(name: String, from config: WorkoutConfig) {
        let preset = WorkoutPreset(displayName: name, config: config)
        custom.insert(preset, at: 0)
        if custom.count > Self.maxPresets {
            custom.removeLast(custom.count - Self.maxPresets)
        }
        persist()
    }

    func delete(_ preset: WorkoutPreset) {
        custom.removeAll { $0.id == preset.id }
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let decoded = try? JSONDecoder().decode([WorkoutPreset].self, from: data) else {
            return
        }
        custom = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(custom) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
