import Foundation

struct ExerciseSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let exerciseType: ExerciseType
    let repsCompleted: Int
    let minutesUnlocked: Int
}
