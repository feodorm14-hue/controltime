import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var manager: ScreenTimeManager
    @AppStorage(StorageKey.isOnboarded) private var isOnboarded = false

    var body: some View {
        if isOnboarded {
            DashboardView()
        } else {
            OnboardingView()
        }
    }
}
