import Foundation
import Combine
import UserNotifications

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var intervalMinutes: Int
    @Published var repsPerInterval: Int
    @Published var exerciseType: ExerciseType
    @Published var isMonitoringActive: Bool
    @Published var graceSkipsRemaining: Int
    @Published var trackedApps: [String]

    private let maxGraceSkips = 4

    private init() {
        let d = AppGroup.defaults
        intervalMinutes = d.object(forKey: StorageKey.intervalMinutes) as? Int ?? 15
        repsPerInterval = d.object(forKey: StorageKey.repsPerInterval) as? Int ?? 15
        exerciseType = ExerciseType(rawValue: d.string(forKey: StorageKey.exerciseType) ?? "") ?? .squats
        isMonitoringActive = d.bool(forKey: "controltime.isMonitoringActive")
        graceSkipsRemaining = d.object(forKey: StorageKey.graceSkipsRemaining) as? Int ?? 4
        trackedApps = d.stringArray(forKey: StorageKey.trackedApps) ?? []
    }

    func requestNotificationPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func persistSettings() {
        let d = AppGroup.defaults
        d.set(intervalMinutes, forKey: StorageKey.intervalMinutes)
        d.set(repsPerInterval, forKey: StorageKey.repsPerInterval)
        d.set(exerciseType.rawValue, forKey: StorageKey.exerciseType)
        d.set(trackedApps, forKey: StorageKey.trackedApps)
    }

    func startMonitoring() {
        persistSettings()
        scheduleNotification()
        isMonitoringActive = true
        AppGroup.defaults.set(true, forKey: "controltime.isMonitoringActive")
    }

    func stopMonitoring() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        isMonitoringActive = false
        AppGroup.defaults.set(false, forKey: "controltime.isMonitoringActive")
    }

    func rewardUnlock() {
        AppGroup.defaults.set(Date().timeIntervalSince1970, forKey: StorageKey.lastUnlockTimestamp)
        if isMonitoringActive { scheduleNotification() }
    }

    func useGraceSkip() -> Bool {
        resetSkipsIfNewDay()
        guard graceSkipsRemaining > 0 else { return false }
        graceSkipsRemaining -= 1
        AppGroup.defaults.set(graceSkipsRemaining, forKey: StorageKey.graceSkipsRemaining)
        if isMonitoringActive { scheduleNotification() }
        return true
    }

    func resetSkipsIfNewDay() {
        let d = AppGroup.defaults
        let lastReset = d.object(forKey: StorageKey.lastSkipResetDate) as? Double ?? 0
        let lastDate = Date(timeIntervalSince1970: lastReset)
        guard !Calendar.current.isDateInToday(lastDate) else { return }
        graceSkipsRemaining = maxGraceSkips
        d.set(maxGraceSkips, forKey: StorageKey.graceSkipsRemaining)
        d.set(Date().timeIntervalSince1970, forKey: StorageKey.lastSkipResetDate)
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["controltime.exercise"])

        let content = UNMutableNotificationContent()
        content.title = "Время вышло!"
        content.body = "Сделай \(repsPerInterval) \(exerciseType.displayName.lowercased()), чтобы продолжить"
        content.sound = .default
        content.userInfo = ["url": "controltime://unlock"]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(intervalMinutes) * 60,
            repeating: false
        )
        let request = UNNotificationRequest(
            identifier: "controltime.exercise",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
