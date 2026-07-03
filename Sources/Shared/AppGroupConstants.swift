import Foundation

enum AppGroup {
    static var defaults: UserDefaults { .standard }
}

enum StorageKey {
    static let repsPerInterval = "controltime.repsPerInterval"
    static let intervalMinutes = "controltime.intervalMinutes"
    static let exerciseType = "controltime.exerciseType"
    static let history = "controltime.history"
    static let unlockDeepLinkScheme = "controltime"
    static let graceSkipsRemaining = "controltime.graceSkipsRemaining"
    static let trackedApps = "controltime.trackedApps"
    static let lastUnlockTimestamp = "controltime.lastUnlockTimestamp"
    static let lastSkipResetDate = "controltime.lastSkipResetDate"
    static let isOnboarded = "controltime.isOnboarded"
    static let monitoringPin = "controltime.monitoringPin"
}

enum ExerciseType: String, CaseIterable, Codable, Identifiable {
    case squats
    case pushups
    case jumpingJacks

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .squats: return "Приседания"
        case .pushups: return "Отжимания"
        case .jumpingJacks: return "Прыжки \"джампинг джек\""
        }
    }
}
