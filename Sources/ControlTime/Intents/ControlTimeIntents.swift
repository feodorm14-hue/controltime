import AppIntents
import UIKit

// MARK: - Действие: Начать упражнение

struct StartExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "Начать упражнение"
    static var description = IntentDescription(
        "Открывает экран упражнения в ControlTime. Используй в автоматизации: когда открываешь TikTok/Instagram → запускается это действие."
    )
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .startExerciseFromIntent, object: nil)
        return .result()
    }
}

// MARK: - Действие: Использовать пропуск

struct UseSkipIntent: AppIntent {
    static var title: LocalizedStringResource = "Пропустить упражнение"
    static var description = IntentDescription(
        "Тратит один из 4 ежедневных пропусков и продлевает время без упражнения."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let manager = ScreenTimeManager.shared
        let ok = manager.useGraceSkip()
        return .result(
            dialog: ok
                ? "Пропуск использован. Осталось \(manager.graceSkipsRemaining) из 4."
                : "Пропуски закончились. Нужно сделать упражнение!"
        )
    }
}

// MARK: - Действие: Статус мониторинга

struct GetStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Статус ControlTime"
    static var description = IntentDescription("Возвращает текущий статус: сколько пропусков осталось и активен ли мониторинг.")
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let m = ScreenTimeManager.shared
        let status = m.isMonitoringActive
            ? "Мониторинг активен. Пропусков: \(m.graceSkipsRemaining)/4."
            : "Мониторинг выключен."
        return .result(value: status, dialog: "\(status)")
    }
}

// MARK: - App Shortcuts (появляются автоматически в приложении Shortcuts)

struct ControlTimeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartExerciseIntent(),
            phrases: [
                "Начать упражнение в \(.applicationName)",
                "Открыть \(.applicationName)",
                "Время упражняться"
            ],
            shortTitle: "Начать упражнение",
            systemImageName: "figure.run"
        )
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let startExerciseFromIntent = Notification.Name("controltime.startExerciseFromIntent")
}
