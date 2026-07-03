import SwiftUI

struct HistoryView: View {
    @ObservedObject private var store = HistoryStore.shared

    var body: some View {
        List {
            if store.sessions.isEmpty {
                Text("Пока нет завершённых разблокировок")
                    .foregroundStyle(.secondary)
            }
            ForEach(store.sessions) { session in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(session.repsCompleted) × \(session.exerciseType.displayName)")
                        .font(.headline)
                    Text("\(session.minutesUnlocked) мин разблокировано · \(session.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("История")
    }
}
