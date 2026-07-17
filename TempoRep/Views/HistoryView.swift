import SwiftUI

/// A plain, native `List` — see `SettingsView`'s doc comment for why: no
/// custom background fighting the system's own materials, so this adapts
/// to light/dark automatically and stays visually correct as OS styling
/// changes underneath it.
struct HistoryView: View {
    let store: HistoryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    emptyState
                } else {
                    recordList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !store.records.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear", role: .destructive) {
                            store.clear()
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
        }
        .tint(Color.accentColor)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No workouts yet", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Finished workouts show up here.")
        }
    }

    private var recordList: some View {
        List {
            ForEach(store.records) { record in
                row(for: record)
            }
            .onDelete { store.delete(at: $0) }
        }
    }

    private func row(for record: WorkoutRecord) -> some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                if let exerciseName = record.exerciseName {
                    Text(verbatim: exerciseName)
                        .font(TempoFont.rounded(.subheadline, weight: .semibold))
                        .lineLimit(1)
                }
                HStack(spacing: Spacing.sm) {
                    Text(record.tempoString)
                        .font(TempoFont.rounded(.title3, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)
                        .accessibilityLabel(Text(verbatim: record.tempoDigits.map(String.init).joined(separator: "-")))
                    Text("\(record.sets)×\(record.repsPerSet)")
                        .font(TempoFont.rounded(.body, weight: .semibold))
                        .monospacedDigit()
                }
                Text(verbatim: record.date.formatted(
                    Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)))
                    .font(TempoFont.rounded(.footnote))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                Text(Self.formatTimeUnderTension(record.timeUnderTension))
                    .font(TempoFont.rounded(.body, weight: .bold))
                    .monospacedDigit()
                Text("under tension")
                    .font(TempoFont.rounded(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    /// Under a minute, "0:15" reads ambiguously (seconds? minutes?) — spell
    /// out the unit instead. Once there's an actual minutes component, m:ss
    /// is unambiguous on its own.
    private static func formatTimeUnderTension(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        if seconds < 60 {
            return "\(seconds)s"
        }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    HistoryView(store: HistoryStore())
}
