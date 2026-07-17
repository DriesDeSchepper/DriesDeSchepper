import SwiftUI

/// The system's standard round, gray "close this sheet" affordance —
/// `xmark.circle.fill` rendered hierarchically — used in place of a text
/// "Done" button across this app's modals, matching how modern system apps
/// (Settings, Maps, News) dismiss non-committal sheets.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2) // a Dynamic Type text style, not a fixed point size
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(Text("Close"))
    }
}
