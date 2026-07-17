import SwiftUI

struct HistoryView: View {
    let store: HistoryStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            ZStack {
                // A plain `.background(Color.black)` on the conditional
                // content below only covers whatever size that content
                // reports — for the empty state (a compact VStack with no
                // spacer) that's just a tight box around the icon and text,
                // not the full screen, leaving a visible black rectangle
                // against the surrounding system dark background. Painting
                // black first, full-bleed, avoids that regardless of which
                // branch is showing.
                Color.black.ignoresSafeArea()
                if store.records.isEmpty {
                    emptyState
                } else {
                    recordList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if !store.records.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear", role: .destructive) {
                            store.clear()
                        }
                        .foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(.secondary)
            Text("No workouts yet")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text("Finished workouts show up here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var recordList: some View {
        List {
            ForEach(store.records) { record in
                row(for: record)
            }
            .onDelete { store.delete(at: $0) }
            .listRowBackground(Color.white.opacity(0.06))
        }
        .scrollContentBackground(.hidden)
    }

    private func row(for record: WorkoutRecord) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let exerciseName = record.exerciseName {
                    Text(verbatim: exerciseName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    Text(record.tempoString)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)
                    Text("\(record.sets)×\(record.repsPerSet)")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                }
                Text(verbatim: record.date.formatted(
                    Date.FormatStyle(date: .abbreviated, time: .shortened).locale(locale)))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(Self.formatTimeUnderTension(record.timeUnderTension))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("under tension")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
        .preferredColorScheme(.dark)
}
