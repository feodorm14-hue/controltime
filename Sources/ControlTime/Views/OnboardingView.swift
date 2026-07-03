import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var manager: ScreenTimeManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text("ControlTime")
                .font(.largeTitle.bold())
            Text("Хочешь листать телефон — сначала подвигайся.\nВыбери приложения, которые нужно ограничить, и назначь \"цену\" в упражнениях.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                Task { await manager.requestAuthorization() }
            } label: {
                Text("Разрешить доступ к экранному времени")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}
