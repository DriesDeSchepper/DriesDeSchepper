import Foundation
import Observation

/// Loads the bundled exercise dataset once and tracks recently-used
/// exercises. No network access — everything ships in the app bundle.
@MainActor
@Observable
final class ExerciseDatabase {
    static let shared = ExerciseDatabase()

    let exercises: [Exercise]
    private(set) var recentIDs: [String] = []

    private static let recentsKey = "recentExerciseIDs"
    private static let maxRecents = 8

    private init() {
        exercises = Self.load()
        recentIDs = UserDefaults.standard.stringArray(forKey: Self.recentsKey) ?? []
    }

    var recents: [Exercise] {
        recentIDs.compactMap { id in exercises.first { $0.id == id } }
    }

    var allMuscles: [String] {
        Set(exercises.flatMap(\.primaryMuscles)).sorted()
    }

    var allEquipment: [String] {
        Set(exercises.compactMap(\.equipment)).sorted()
    }

    func exercise(id: String?) -> Exercise? {
        guard let id else { return nil }
        return exercises.first { $0.id == id }
    }

    func markUsed(_ exercise: Exercise) {
        recentIDs.removeAll { $0 == exercise.id }
        recentIDs.insert(exercise.id, at: 0)
        if recentIDs.count > Self.maxRecents {
            recentIDs.removeLast(recentIDs.count - Self.maxRecents)
        }
        UserDefaults.standard.set(recentIDs, forKey: Self.recentsKey)
    }

    private static func load() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Exercise].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.name < $1.name }
    }
}
