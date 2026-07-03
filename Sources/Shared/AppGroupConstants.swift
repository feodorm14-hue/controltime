import Foundation
import ManagedSettings

enum AppGroup {
    static let identifier = "group.com.controltime.app"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

enum StorageKey {
    static let selection = "controltime.selection"
    static let repsPerInterval = "controltime.repsPerInterval"
    static let intervalMinutes = "controltime.intervalMinutes"
    static let exerciseType = "controltime.exerciseType"
    static let isShieldedFlag = "controltime.isShielded"
    static let history = "controltime.history"
    static let unlockDeepLinkScheme = "controltime"
    static let graceSkipsRemaining = "controltime.graceSkipsRemaining"
    static let maxGraceSkips = "controltime.maxGraceSkips"
}

extension ManagedSettingsStore.Name {
    static let controlTime: Self = "ControlTimeShield"
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
