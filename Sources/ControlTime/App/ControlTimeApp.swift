import SwiftUI

@main
struct ControlTimeApp: App {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
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
                    guard url.scheme == StorageKey.unlockDeepLinkScheme,
                          url.host == "unlock" else { return }
                    showExercise = true
                }
                .task {
                    screenTimeManager.resetSkipsIfNewDay()
                    await screenTimeManager.requestNotificationPermission()
                }
        }
    }
}
