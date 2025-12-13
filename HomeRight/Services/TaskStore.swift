import Foundation
import Combine
import SwiftUI
import UserNotifications

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var groupedTasks: [Schedule: [Task]] = [:]
    @Published var selectedSchedule: Schedule? = nil
    @Published var selectedYear: Int = 2024
    @Published private var progress: [String: TaskProgress] = [:]

    init() {
        regroupTasks()
    }

    func regroupTasks() {
        groupedTasks = Dictionary(grouping: ChecklistData.tasks, by: { $0.schedule })
    }

    func progress(for task: Task, year: Int? = nil, month: Int? = nil) -> TaskProgress {
        let key = progressKey(for: task, year: year ?? selectedYear, month: month)
        return progress[key] ?? TaskProgress()
    }

    func updateStatus(for task: Task, to status: TaskStatus, year: Int? = nil, month: Int? = nil) {
        let year = year ?? selectedYear
        let key = progressKey(for: task, year: year, month: month)
        var current = progress[key] ?? TaskProgress()
        current.status = status
        progress[key] = current
    }

    func updateCost(for task: Task, cost: Decimal?, year: Int? = nil, month: Int? = nil) {
        let year = year ?? selectedYear
        let key = progressKey(for: task, year: year, month: month)
        var current = progress[key] ?? TaskProgress()
        current.cost = cost
        progress[key] = current
    }

    func updateNote(for task: Task, note: String, year: Int? = nil, month: Int? = nil) {
        let year = year ?? selectedYear
        let key = progressKey(for: task, year: year, month: month)
        var current = progress[key] ?? TaskProgress()
        current.note = note
        progress[key] = current
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

    var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(2024...max(2024, currentYear))
    }

    func tasks(in month: Int) -> [Task] {
        ChecklistData.tasks.filter { schedule($0.schedule, matches: month) }
    }

    func isMonthComplete(_ month: Int, year: Int? = nil) -> Bool {
        let year = year ?? selectedYear
        let tasksForMonth = tasks(in: month)
        guard !tasksForMonth.isEmpty else { return false }
        return tasksForMonth.allSatisfy { progress(for: $0, year: year, month: month).status == .complete }
    }

    func monthCost(_ month: Int, year: Int? = nil) -> Decimal {
        let year = year ?? selectedYear
        let tasksForMonth = tasks(in: month)
        return tasksForMonth
            .compactMap { progress(for: $0, year: year, month: month).cost }
            .reduce(Decimal(0)) { $0 + $1 }
    }

    var suggestedMonthlyBudget: Decimal {
        Decimal(150)
    }

    var totalCompletedCost: Decimal {
        progress
            .filter { key, value in
                key.contains("-\(selectedYear)-") && value.status == .complete
            }
            .compactMap { $0.value.cost }
            .reduce(Decimal(0)) { $0 + $1 }
    }

    var completedCount: Int {
        progress
            .filter { key, value in
                key.contains("-\(selectedYear)-") && value.status == .complete
            }
            .count
    }

    var yearProgress: Double {
        let months = Array(1...12)
        let monthsWithTasks = months.filter { !tasks(in: $0).isEmpty }
        guard !monthsWithTasks.isEmpty else { return 0 }
        let completedMonths = monthsWithTasks.filter { isMonthComplete($0) }
        let ratio = Double(completedMonths.count) / Double(monthsWithTasks.count)
        return max(0, min(1, ratio))
    }

    private func progressKey(for task: Task, year: Int, month: Int?) -> String {
        let monthValue: Int
        if let month {
            monthValue = month
        } else {
            monthValue = Calendar.current.component(.month, from: Date())
        }
        return "\(task.id.uuidString)-\(year)-\(monthValue)"
    }

    private func schedule(_ schedule: Schedule, matches month: Int) -> Bool {
        switch schedule {
        case .monthly:
            return (1...12).contains(month)
        case .quarterly:
            return [1, 4, 7, 10].contains(month)
        case .annual:
            return month == 1
        case .spring:
            return month == 3
        case .summer:
            return month == 6
        case .fall:
            return month == 9
        case .winter:
            return month == 12
        case .seasonal:
            return month == 3
        }
    }
}
