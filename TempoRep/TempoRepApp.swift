import SwiftUI

@main
struct TempoRepApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @State private var engine = WorkoutEngine()
    private let localization = LocalizationManager.shared

    var body: some View {
        ZStack {
            if engine.state == .idle {
                SetupView(engine: engine)
                    .transition(.opacity)
            } else {
                WorkoutView(engine: engine)
                    .transition(.opacity)
            }
        }
        .environment(\.locale, localization.locale)
        .animation(.easeInOut(duration: 0.25), value: engine.state == .idle)
    }
}

#Preview {
    RootView()
}
