import Foundation
import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    nonisolated func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            print("Notifications granted: \(granted)")
        }
    }

    func registerReminders(for tasks: [Task]) async {
        let center = UNUserNotificationCenter.current()
        await center.removeAllPendingNotificationRequests()

        for task in tasks {
            let content = UNMutableNotificationContent()
            content.title = task.title
            content.body = task.detail
            content.sound = .default

            let triggers = triggers(for: task.schedule)
            for (index, trigger) in triggers.enumerated() {
                let identifier = "\(task.id.uuidString)-\(index)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    private func triggers(for schedule: Schedule) -> [UNCalendarNotificationTrigger] {
        switch schedule {
        case .quarterly:
            return quarterlyTriggers()
        default:
            return [calendarTrigger(for: schedule)]
        }
    }

    private func calendarTrigger(for schedule: Schedule) -> UNCalendarNotificationTrigger {
        var dateComponents = DateComponents()
        switch schedule {
        case .monthly:
            dateComponents.day = 1
            dateComponents.hour = 9
        case .quarterly:
            // Fallback: not used because quarterly schedules use multiple triggers, but kept for exhaustiveness
            dateComponents.month = 1
            dateComponents.day = 1
            dateComponents.hour = 9
        case .annual:
            dateComponents.month = 1
            dateComponents.day = 15
            dateComponents.hour = 9
        case .spring:
            dateComponents.month = 3
            dateComponents.day = 15
            dateComponents.hour = 9
        case .summer:
            dateComponents.month = 6
            dateComponents.day = 15
            dateComponents.hour = 9
        case .fall:
            dateComponents.month = 9
            dateComponents.day = 15
            dateComponents.hour = 9
        case .winter:
            dateComponents.month = 12
            dateComponents.day = 1
            dateComponents.hour = 9
        case .seasonal:
            dateComponents.month = 3
            dateComponents.day = 1
            dateComponents.hour = 9
        }

        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }

    private func quarterlyTriggers() -> [UNCalendarNotificationTrigger] {
        let months = [1, 4, 7, 10]
        return months.map { month in
            var components = DateComponents()
            components.month = month
            components.day = 1
            components.hour = 9
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
    }
}
