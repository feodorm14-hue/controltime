import Foundation
import Combine

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var sessions: [ExerciseSession] = []

    private init() {
        load()
    }

    func append(_ session: ExerciseSession) {
        sessions.insert(session, at: 0)
        save()
    }

    private func load() {
        guard let data = AppGroup.defaults.data(forKey: StorageKey.history),
              let decoded = try? JSONDecoder().decode([ExerciseSession].self, from: data) else { return }
        sessions = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        AppGroup.defaults.set(data, forKey: StorageKey.history)
    }
}
