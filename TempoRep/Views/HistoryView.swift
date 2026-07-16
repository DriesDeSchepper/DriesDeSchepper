import SwiftUI

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
            .background(Color.black)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
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
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
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
                Text(Self.mmss(record.timeUnderTension))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("under tension")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private static func mmss(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    HistoryView(store: HistoryStore())
        .preferredColorScheme(.dark)
}
