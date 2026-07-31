import UIKit

/// The app is portrait-only everywhere except during an active workout,
/// where landscape is genuinely useful (phone propped on a shelf, in a
/// tripod, etc.) — see `WorkoutView`. Info.plist declares all the
/// orientations as *possible*; this is what actually restricts them at
/// runtime per screen, since SwiftUI has no native per-view orientation
/// lock. `AppDelegate.application(_:supportedInterfaceOrientationsFor:)`
/// is asked by the system whenever it needs to know what's currently
/// allowed, and answers from `OrientationLock.mask`.
@MainActor
enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = .portrait

    /// Call after changing `mask` so the system re-evaluates the current
    /// orientation immediately: this doesn't force an unprompted rotation
    /// while the device is held still, but it does mean landscape becomes
    /// available the moment the mask allows it, without waiting on some
    /// unrelated later trigger to notice.
    static func apply() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                      supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}
