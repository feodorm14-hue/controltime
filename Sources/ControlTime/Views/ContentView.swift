import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject private var manager: ScreenTimeManager

    var body: some View {
        Group {
            if manager.authorizationStatus == .approved {
                DashboardView()
            } else {
                OnboardingView()
            }
        }
        .task {
            manager.refreshAuthorizationStatus()
        }
    }
}
