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
    @State private var showSplash = true
    private let localization = LocalizationManager.shared

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if engine.state == .idle {
                SetupView(engine: engine)
                    .transition(.opacity)
            } else {
                WorkoutView(engine: engine)
                    .transition(.opacity)
            }
        }
        .environment(\.locale, localization.locale)
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .animation(.easeInOut(duration: 0.25), value: engine.state == .idle)
        .task {
            try? await Task.sleep(for: .seconds(1.1))
            showSplash = false
        }
    }
}

#Preview {
    RootView()
}
