import Foundation
import UserNotifications

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var groupedTasks: [Schedule: [Task]] = [:]
    @Published var selectedSchedule: Schedule? = nil

    init() {
        regroupTasks()
    }

    func regroupTasks() {
        groupedTasks = Dictionary(grouping: ChecklistData.tasks, by: { $0.schedule })
    }

    func refreshNotifications() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }
        await NotificationManager.shared.registerReminders(for: ChecklistData.tasks)
    }

    var schedules: [Schedule] {
        Schedule.allCases.filter { groupedTasks[$0] != nil }
    }
}
