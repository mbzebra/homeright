import Foundation

struct Task: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let schedule: Schedule
}

enum TaskStatus: String, CaseIterable, Codable, Hashable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case complete = "Complete"

    var displayName: String { rawValue }
}

struct TaskProgress: Codable, Hashable {
    var status: TaskStatus = .notStarted
    var cost: Decimal? = nil
    var note: String = ""
}

enum Schedule: String, CaseIterable, Codable, Hashable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case seasonal = "Seasonal"
    case annual = "Annual"
    case spring = "Spring"
    case summer = "Summer"
    case fall = "Fall"
    case winter = "Winter"

    var displayName: String { rawValue }
}
