import Foundation

struct Task: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let detail: String
    let schedule: Schedule
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
    case custom = "Custom"

    var displayName: String { rawValue }
}
