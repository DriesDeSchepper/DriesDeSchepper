import SwiftUI

@main
struct TempoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @State private var engine = WorkoutEngine()

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
        .animation(.easeInOut(duration: 0.25), value: engine.state == .idle)
    }
}

#Preview {
    RootView()
}
