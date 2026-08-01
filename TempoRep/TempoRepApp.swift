import SwiftUI

@main
struct TempoRepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// No forced color scheme anywhere: every screen follows the system
/// appearance, resolving through the tokens in DesignSystem.swift.
struct RootView: View {
    @State private var engine = WorkoutEngine()
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        .animation(TempoAnimation.standard(reduceMotion: reduceMotion), value: showSplash)
        .animation(TempoAnimation.standard(reduceMotion: reduceMotion), value: engine.state == .idle)
        .task {
            try? await Task.sleep(for: .seconds(1.1))
            showSplash = false
        }
    }
}

#Preview {
    RootView()
}
