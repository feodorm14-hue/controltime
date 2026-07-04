import AppIntents
import UIKit

// MARK: - Действие: Начать упражнение

struct StartExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "Начать упражнение"
    static var description = IntentDescription(
        "Используй в автоматизации «Когда открывается приложение». Сам проверяет — нужно ли упражнение. Если недавно выполнено — просто открывает дашборд. Если нет — экран упражнения."
    )
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let d = AppGroup.defaults
        let isMonitoring = d.bool(forKey: "controltime.isMonitoringActive")
        let lastUnlock = d.double(forKey: StorageKey.lastUnlockTimestamp)
        let intervalMinutes = d.object(forKey: StorageKey.intervalMinutes) as? Int ?? 15
        let elapsed = Date().timeIntervalSince1970 - lastUnlock
        let needsExercise = isMonitoring && (lastUnlock == 0 || elapsed >= Double(intervalMinutes) * 60)

        if needsExercise {
            NotificationCenter.default.post(name: .startExerciseFromIntent, object: nil)
        }
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

// MARK: - Действие: Проверить — разблокировано ли?

struct IsUnlockedIntent: AppIntent {
    static var title: LocalizedStringResource = "Упражнение выполнено?"
    static var description = IntentDescription(
        "Возвращает ДА если упражнение было выполнено недавно (в рамках текущего интервала). Используй в условии «Если» автоматизации: если НЕТ — запускай «Начать упражнение»."
    )
    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let m = ScreenTimeManager.shared
        guard m.isMonitoringActive else {
            return .result(value: true)
        }
        let lastUnlock = AppGroup.defaults.double(forKey: StorageKey.lastUnlockTimestamp)
        guard lastUnlock > 0 else {
            return .result(value: false)
        }
        let elapsed = Date().timeIntervalSince1970 - lastUnlock
        let intervalSeconds = Double(m.intervalMinutes) * 60
        let unlocked = elapsed < intervalSeconds
        return .result(value: unlocked)
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
