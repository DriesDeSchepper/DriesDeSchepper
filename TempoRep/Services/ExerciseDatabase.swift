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
    private(set) var favoriteIDs: Set<String> = []

    private static let recentsKey = "recentExerciseIDs"
    private static let favoritesKey = "favoriteExerciseIDs"
    private static let maxRecents = 8

    private init() {
        exercises = Self.load()
        recentIDs = UserDefaults.standard.stringArray(forKey: Self.recentsKey) ?? []
        favoriteIDs = Set(UserDefaults.standard.stringArray(forKey: Self.favoritesKey) ?? [])
    }

    var recents: [Exercise] {
        recentIDs.compactMap { id in exercises.first { $0.id == id } }
    }

    /// `exercises` is already name-sorted, so filtering it (rather than
    /// mapping `favoriteIDs`) keeps favorites in the same alphabetical order
    /// as the rest of the picker instead of "most recently favorited".
    var favorites: [Exercise] {
        exercises.filter { favoriteIDs.contains($0.id) }
    }

    func isFavorite(_ exercise: Exercise) -> Bool {
        favoriteIDs.contains(exercise.id)
    }

    func toggleFavorite(_ exercise: Exercise) {
        if favoriteIDs.contains(exercise.id) {
            favoriteIDs.remove(exercise.id)
        } else {
            favoriteIDs.insert(exercise.id)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: Self.favoritesKey)
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
