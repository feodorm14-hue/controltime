import DeviceActivity
import ManagedSettings
import FamilyControls

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .controlTime)

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        applyShield()
    }

    private func applyShield() {
        guard let data = AppGroup.defaults.data(forKey: StorageKey.selection),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return
        }

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens

        AppGroup.defaults.set(true, forKey: StorageKey.isShieldedFlag)
    }
}
