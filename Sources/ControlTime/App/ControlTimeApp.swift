import SwiftUI

@main
struct ControlTimeApp: App {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showExercise = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenTimeManager)
                .fullScreenCover(isPresented: $showExercise) {
                    ExerciseView()
                        .environmentObject(screenTimeManager)
                }
                .onOpenURL { url in
                    guard url.scheme == StorageKey.unlockDeepLinkScheme, url.host == "unlock" else { return }
                    showExercise = true
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    screenTimeManager.refreshAuthorizationStatus()
                    if AppGroup.defaults.bool(forKey: StorageKey.isShieldedFlag) {
                        showExercise = true
                    }
                }
        }
    }
}
