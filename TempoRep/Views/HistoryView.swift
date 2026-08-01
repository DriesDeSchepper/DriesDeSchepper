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
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton { dismiss() }
                }
                if !store.records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) {
                            store.clear()
                        }
                    }
                }
            }
        }
        .tint(Color.accentColor)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No workouts yet", systemImage: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
        } description: {
            Text("Finished workouts show up here.")
        }
    }

    private var recordList: some View {
        List {
            ForEach(store.records) { record in
                row(for: record)
                    .listRowInsets(EdgeInsets(top: Spacing.md, leading: Spacing.lg,
                                              bottom: Spacing.md, trailing: Spacing.lg))
            }
            .onDelete { store.delete(at: $0) }
        }
        .listStyle(.plain)
    }

    /// A feed card rather than a text row: the stats read as figures, and
    /// the tempo shape makes two sessions of the same lift comparable at a
    /// glance — a slow eccentric with an explosive drive looks visibly
    /// different from an even 3-0-3-0, which a digit string never showed.
    private func row(for record: WorkoutRecord) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: record.exerciseName ?? L("No exercise selected", locale))
                    .font(TempoFont.rounded(.headline, weight: .bold))
                    .lineLimit(1)
                Spacer(minLength: Spacing.sm)
                Text(verbatim: record.date.formatted(
                    Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)))
                    .font(TempoFont.rounded(.caption2, weight: .semibold))
                    .tracking(TempoTracking.label)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(alignment: .bottom, spacing: Spacing.xl) {
                StatBlock(value: Self.formatTimeUnderTension(record.timeUnderTension),
                          label: "stat.underTension")
                StatBlock(value: "\(record.sets)×\(record.repsPerSet)", label: "stat.volume")
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    TempoShape(digits: record.tempoDigits)
                        .frame(width: TempoMetrics.tempoShapeWidth)
                    Text(verbatim: record.tempoString)
                        .font(TempoFont.rounded(.caption2, weight: .semibold))
                        .tracking(TempoTracking.label)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
