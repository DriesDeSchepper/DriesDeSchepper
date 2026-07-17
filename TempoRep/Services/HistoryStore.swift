import Foundation
import Observation

/// Persists completed workouts as JSON in UserDefaults, newest first.
@MainActor
@Observable
final class HistoryStore {
    private(set) var records: [WorkoutRecord] = []

    private static let defaultsKey = "workoutHistory"
    private static let maxRecords = 200

    init() {
        load()
    }

    func add(_ record: WorkoutRecord) {
        records.insert(record, at: 0)
        if records.count > Self.maxRecords {
            records.removeLast(records.count - Self.maxRecords)
        }
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    func clear() {
        records.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let decoded = try? JSONDecoder().decode([WorkoutRecord].self, from: data) else {
            return
        }
        records = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
