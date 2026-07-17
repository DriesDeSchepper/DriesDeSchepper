import SwiftUI
import UIKit

struct ExercisePickerView: View {
    @Bindable var engine: WorkoutEngine
    @Environment(\.dismiss) private var dismiss
    private let database = ExerciseDatabase.shared

    @State private var searchText = ""
    @State private var muscleFilter: String?
    @State private var equipmentFilter: String?

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
            .listRowBackground(Color.white.opacity(0.06))
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .searchable(text: $searchText, prompt: Text("Search exercises"))
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Muscle", selection: $muscleFilter) {
                            Text("All muscles").tag(String?.none)
                            ForEach(database.allMuscles, id: \.self) { muscle in
                                Text(verbatim: muscle.capitalized).tag(Optional(muscle))
                            }
                        }
                        Picker("Equipment", selection: $equipmentFilter) {
                            Text("All equipment").tag(String?.none)
                            ForEach(database.allEquipment, id: \.self) { equipment in
                                Text(verbatim: equipment.capitalized).tag(Optional(equipment))
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Color.accentColor)
    }

    private var filteredExercises: [Exercise] {
        database.exercises.filter { exercise in
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
                && (muscleFilter == nil || exercise.primaryMuscles.contains(muscleFilter!))
                && (equipmentFilter == nil || exercise.equipment == equipmentFilter)
        }
    }

    private func row(_ exercise: Exercise) -> some View {
        Button {
            select(exercise)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(verbatim: exercise.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(verbatim: captionText(exercise))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
        database.markUsed(exercise)
        dismiss()
    }
}

#Preview {
    ExercisePickerView(engine: WorkoutEngine())
        .preferredColorScheme(.dark)
}
