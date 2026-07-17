import SwiftUI
import UIKit

/// A plain, native `List` — see `SettingsView`'s doc comment for why.
struct ExercisePickerView: View {
    @Bindable var engine: WorkoutEngine
    @Environment(\.dismiss) private var dismiss
    private let database = ExerciseDatabase.shared

    @State private var searchText = ""
    @State private var muscleFilter: String?
    @State private var equipmentFilter: String?
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty, muscleFilter == nil, equipmentFilter == nil {
                    if engine.config.selectedExerciseID != nil {
                        Section {
                            Button(role: .destructive) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                engine.config.selectedExerciseID = nil
                                dismiss()
                            } label: {
                                Text("No exercise (bare timer)")
                            }
                        }
                    }
                    if !database.favorites.isEmpty {
                        Section {
                            ForEach(database.favorites) { exercise in
                                row(exercise)
                            }
                        } header: {
                            Text("Favorites")
                        }
                    }
                    if !database.recents.isEmpty {
                        Section {
                            ForEach(database.recents) { exercise in
                                row(exercise)
                            }
                        } header: {
                            Text("Recent")
                        }
                    }
                }

                Section {
                    ForEach(filteredExercises) { exercise in
                        row(exercise)
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("Search exercises"))
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: activeFilterCount > 0
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel(Text("Filters"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(muscles: database.allMuscles, equipment: database.allEquipment,
                            muscleFilter: $muscleFilter, equipmentFilter: $equipmentFilter)
                    .presentationDetents([.medium, .large])
            }
        }
        .tint(Color.accentColor)
    }

    private var activeFilterCount: Int {
        (muscleFilter == nil ? 0 : 1) + (equipmentFilter == nil ? 0 : 1)
    }

    private var filteredExercises: [Exercise] {
        database.exercises.filter { exercise in
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
                && (muscleFilter == nil || exercise.primaryMuscles.contains(muscleFilter!))
                && (equipmentFilter == nil || exercise.equipment == equipmentFilter)
        }
    }

    private func row(_ exercise: Exercise) -> some View {
        HStack(spacing: Spacing.md) {
            Button {
                select(exercise)
            } label: {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(verbatim: exercise.name)
                        .font(TempoFont.rounded(.callout, weight: .semibold))
                    Text(verbatim: captionText(exercise))
                        .font(TempoFont.rounded(.caption))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                database.toggleFavorite(exercise)
            } label: {
                Image(systemName: database.isFavorite(exercise) ? "star.fill" : "star")
                    .font(TempoFont.rounded(.body))
                    .foregroundStyle(database.isFavorite(exercise) ? .yellow : .secondary)
                    .frame(width: TempoMetrics.minTapTarget, height: TempoMetrics.minTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(database.isFavorite(exercise) ? "Remove from favorites" : "Add to favorites"))
        }
        .contentShape(Rectangle())
    }

    private func captionText(_ exercise: Exercise) -> String {
        var parts: [String] = []
        if let muscle = exercise.primaryMuscles.first { parts.append(muscle.capitalized) }
        if let equipment = exercise.equipment { parts.append(equipment.capitalized) }
        return parts.joined(separator: " · ")
    }

    private func select(_ exercise: Exercise) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        engine.config.selectedExerciseID = exercise.id
        if exercise.isUnilateral {
            engine.config.unilateral = true
        }
        engine.config.startPhase = exercise.startPhase
        if let suggested = exercise.suggestedTempo {
            engine.config.tempoDigits = suggested
        }
        database.markUsed(exercise)
        dismiss()
    }
}

/// A plain scrollable List, unlike the cramped Menu-nested-Picker this
/// replaced — that layout made it easy to lose track of options near the
/// end of a long alphabetical list (e.g. "Triceps", last of 17 muscles).
private struct FilterSheet: View {
    let muscles: [String]
    let equipment: [String]
    @Binding var muscleFilter: String?
    @Binding var equipmentFilter: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    selectableRow(isSelected: muscleFilter == nil) {
                        muscleFilter = nil
                    } label: {
                        Text("All muscles")
                    }
                    ForEach(muscles, id: \.self) { muscle in
                        selectableRow(isSelected: muscleFilter == muscle) {
                            muscleFilter = muscle
                        } label: {
                            Text(verbatim: muscle.capitalized)
                        }
                    }
                } header: {
                    Text("Muscle")
                }

                Section {
                    selectableRow(isSelected: equipmentFilter == nil) {
                        equipmentFilter = nil
                    } label: {
                        Text("All equipment")
                    }
                    ForEach(equipment, id: \.self) { item in
                        selectableRow(isSelected: equipmentFilter == item) {
                            equipmentFilter = item
                        } label: {
                            Text(verbatim: item.capitalized)
                        }
                    }
                } header: {
                    Text("Equipment")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton { dismiss() }
                }
            }
        }
        .tint(Color.accentColor)
    }

    private func selectableRow(
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack {
                label()
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ExercisePickerView(engine: WorkoutEngine())
}
