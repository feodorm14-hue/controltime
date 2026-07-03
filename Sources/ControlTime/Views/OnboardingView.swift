import SwiftUI

struct OnboardingView: View {
    @AppStorage(StorageKey.isOnboarded) private var isOnboarded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.strengthtraining.functional")
                            .font(.system(size: 72))
                            .foregroundStyle(.green)
                        Text("ControlTime")
                            .font(.largeTitle.bold())
                        Text("Хочешь листать телефон — сначала подвигайся.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Как это работает")
                            .font(.title2.bold())

                        stepRow(number: "1", title: "Настрой интервал", body: "Выбери, как часто ты хочешь делать упражнения — например, каждые 15 минут.")
                        stepRow(number: "2", title: "Включи мониторинг", body: "Приложение будет отправлять уведомление через заданный интервал.")
                        stepRow(number: "3", title: "Настрой Shortcuts", body: "Добавь автоматизацию: когда открываешь TikTok / Instagram — открыть ControlTime.")
                        stepRow(number: "4", title: "Занимайся!", body: "Приложение считает повторения через камеру. Засчитал — получил право использовать телефон.")
                    }
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Настройка Shortcuts (один раз)")
                            .font(.title3.bold())
                            .padding(.horizontal, 24)

                        shortcutsGuideCard
                    }

                    Button {
                        isOnboarded = true
                    } label: {
                        Text("Начать!")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var shortcutsGuideCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            guideStep("1", "Открой приложение «Быстрые команды» (Shortcuts)")
            guideStep("2", "Перейди во вкладку «Автоматизация»")
            guideStep("3", "Нажми «+» → «Приложение»")
            guideStep("4", "Выбери нужное приложение (например, TikTok)")
            guideStep("5", "Выбери «При открытии»")
            guideStep("6", "Добавь действие «Открыть URL»")
            guideStep("7", "Введи URL: controltime://unlock")
            guideStep("8", "Сними галку «Спрашивать перед запуском»")
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }

    private func stepRow(number: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.green)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private func guideStep(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number + ".")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .leading)
            Text(text)
                .font(.subheadline)
        }
    }
}
