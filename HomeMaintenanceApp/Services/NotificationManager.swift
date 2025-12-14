import Foundation
import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() {
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

            let trigger = trigger(for: task.schedule)
            let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private func trigger(for schedule: Schedule) -> UNCalendarNotificationTrigger {
        var dateComponents = DateComponents()
        switch schedule {
        case .monthly:
            dateComponents.day = 1
            dateComponents.hour = 9
        case .quarterly:
            dateComponents.month = currentQuarterStart()
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
        case .custom:
            dateComponents.day = nil
        }

        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }

    private func currentQuarterStart() -> Int {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 1...3: return 1
        case 4...6: return 4
        case 7...9: return 7
        default: return 10
        }
    }
}
