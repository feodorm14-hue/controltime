import Foundation
import Combine
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var selection: FamilyActivitySelection
    @Published var intervalMinutes: Int
    @Published var repsPerInterval: Int
    @Published var exerciseType: ExerciseType
    @Published var isMonitoringActive: Bool

    private let store = ManagedSettingsStore(named: .controlTime)
    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("controltime.daily")
    private let eventName = DeviceActivityEvent.Name("controltime.threshold")

    private init() {
        let defaults = AppGroup.defaults
        intervalMinutes = defaults.object(forKey: StorageKey.intervalMinutes) as? Int ?? 15
        repsPerInterval = defaults.object(forKey: StorageKey.repsPerInterval) as? Int ?? 15
        exerciseType = ExerciseType(rawValue: defaults.string(forKey: StorageKey.exerciseType) ?? "") ?? .squats
        isMonitoringActive = defaults.bool(forKey: "controltime.isMonitoringActive")

        if let data = defaults.data(forKey: StorageKey.selection),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = decoded
        } else {
            selection = FamilyActivitySelection()
        }
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Family Controls authorization failed: \(error)")
        }
        refreshAuthorizationStatus()
    }

    func persistSelection() {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        AppGroup.defaults.set(data, forKey: StorageKey.selection)
    }

    func persistSettings() {
        let defaults = AppGroup.defaults
        defaults.set(intervalMinutes, forKey: StorageKey.intervalMinutes)
        defaults.set(repsPerInterval, forKey: StorageKey.repsPerInterval)
        defaults.set(exerciseType.rawValue, forKey: StorageKey.exerciseType)
    }

    func startMonitoring() {
        persistSelection()
        persistSettings()
        unshieldAll()

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let threshold = DateComponents(minute: intervalMinutes)
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: threshold
        )

        do {
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
            isMonitoringActive = true
            AppGroup.defaults.set(true, forKey: "controltime.isMonitoringActive")
        } catch {
            print("Failed to start monitoring: \(error)")
            isMonitoringActive = false
        }
    }

    func stopMonitoring() {
        center.stopMonitoring([activityName])
        isMonitoringActive = false
        AppGroup.defaults.set(false, forKey: "controltime.isMonitoringActive")
        unshieldAll()
    }

    func unshieldAll() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        AppGroup.defaults.set(false, forKey: StorageKey.isShieldedFlag)
    }

    /// Снимает текущую блокировку и открывает новое временное окно —
    /// DeviceActivity считает использование нарастающим итогом внутри окна,
    /// поэтому единственный способ повторно получить порог "N минут" — пересоздать мониторинг.
    func rewardUnlock() {
        guard isMonitoringActive else { return }
        center.stopMonitoring([activityName])
        startMonitoring()
    }
}
