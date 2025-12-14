import SwiftUI

struct HomeLandingView: View {
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    heroCard
                    groupedTasks
                    shortcutGrid
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Home Maintenance")
                    .font(.title2.weight(.semibold))
                Text("Good to see you")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 42, height: 42)
                .foregroundStyle(.blue)
                .padding(6)
                .background(.thinMaterial)
                .clipShape(Circle())
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title3.weight(.semibold))
            Text(urgencyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.2), Color.green.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "house.fill")
                .font(.system(size: 42))
                .foregroundStyle(.blue)
                .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var groupedTasks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This month's maintenance")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: TaskListView().environmentObject(taskStore)) {
                    Text("View all")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if allTasksComplete {
                completionRow
            } else {
                if !attentionTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Needs attention")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(attentionPreview, id: \.id) { task in
                            taskRow(task)
                        }
                        if attentionTasks.count > attentionPreview.count {
                            NavigationLink(destination: TaskListView().environmentObject(taskStore)) {
                                moreIndicator(count: attentionTasks.count - attentionPreview.count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !upcomingTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Upcoming")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(upcomingPreview, id: \.task.id) { item in
                            taskRow(item.task, month: item.month)
                        }
                        if upcomingTasks.count > upcomingPreview.count {
                            NavigationLink(destination: TaskListView().environmentObject(taskStore)) {
                                moreIndicator(count: upcomingTasks.count - upcomingPreview.count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !recentlyCompleted.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recently completed")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(recentlyCompletedPreview, id: \.id) { task in
                            taskRow(task, muted: true)
                        }
                        if recentlyCompleted.count > recentlyCompletedPreview.count {
                            NavigationLink(destination: TaskListView().environmentObject(taskStore)) {
                                moreIndicator(count: recentlyCompleted.count - recentlyCompletedPreview.count)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func taskRow(_ task: Task, month: Int? = nil, muted: Bool = false) -> some View {
        NavigationLink(destination: TaskDetailView(task: task, month: nil).environmentObject(taskStore)) {
            HStack(spacing: 12) {
                Image(systemName: statusIcon(for: task, month: month))
                    .foregroundStyle(statusColor(for: task, month: month))
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .opacity(muted ? 0.7 : 1)
                    Text(task.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var completionRow: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text("All tasks completed for now")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var shortcutGrid: some View {
        let items: [(String, String, AnyView)] = [
            ("list.bullet.clipboard", "Home Tasks", AnyView(TaskListView().environmentObject(taskStore))),
            ("bell.badge", "Reminders", AnyView(ReminderSettingsView())),
            ("wrench.and.screwdriver", "Service History", AnyView(Text("Service History (coming soon)").padding())),
            ("person.2.wave.2", "Find a Pro", AnyView(Text("Find a Pro (coming soon)").padding()))
        ]
        return VStack(alignment: .leading, spacing: 8) {
            Text("Shortcuts")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(items, id: \.1) { item in
                    NavigationLink(destination: item.2) {
                        VStack(spacing: 8) {
                            Image(systemName: item.0)
                                .font(.title3)
                                .foregroundStyle(.blue.opacity(0.6))
                                .padding(10)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                            Text(item.1)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }

    private var previewTasks: [Task] {
        Array(ChecklistData.tasks.prefix(3))
    }

    private var attentionTasks: [Task] {
        ChecklistData.tasks.filter { taskStore.progress(for: $0).status == .inProgress }
    }

    private var attentionPreview: [Task] {
        Array(attentionTasks.prefix(2))
    }

    private var upcomingTasks: [(task: Task, month: Int)] {
        var seen = Set<UUID>()
        var items: [(Task, Int)] = []
        for month in monthsForUpcoming {
            for task in taskStore.tasks(in: month) {
                guard taskStore.progress(for: task, month: month).status == .notStarted else { continue }
                if seen.insert(task.id).inserted {
                    items.append((task, month))
                }
            }
        }
        return items
    }

    private var upcomingPreview: [(task: Task, month: Int)] {
        Array(upcomingTasks.prefix(2))
    }

    private var recentlyCompleted: [Task] {
        ChecklistData.tasks.filter { taskStore.progress(for: $0).status == .complete }
    }

    private var recentlyCompletedPreview: [Task] {
        Array(recentlyCompleted.prefix(2))
    }

    private var allTasksComplete: Bool {
        ChecklistData.tasks.allSatisfy { taskStore.progress(for: $0).status == .complete }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var urgencyMessage: String {
        let inProgress = ChecklistData.tasks.filter { taskStore.progress(for: $0).status == .inProgress }
        if inProgress.isEmpty {
            return "Everything is on track."
        } else if inProgress.count <= 3 {
            return "\(inProgress.count) task\(inProgress.count == 1 ? "" : "s") need attention soon."
        } else {
            return "A few tasks need attention soon."
        }
    }

    private func statusIcon(for task: Task, month: Int? = nil) -> String {
        switch taskStore.progress(for: task, month: month).status {
        case .complete: return "checkmark.circle.fill"
        case .inProgress: return "clock.fill"
        case .notStarted: return "circle"
        }
    }

    private func statusColor(for task: Task, month: Int? = nil) -> Color {
        switch taskStore.progress(for: task, month: month).status {
        case .complete: return .green
        case .inProgress: return .orange
        case .notStarted: return .gray
        }
    }

    private func moreIndicator(count: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(.secondary)
            Text("+\(count) more")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var monthsForUpcoming: [Int] {
        var months = [currentMonth]
        if shouldIncludeNextMonth { months.append(nextMonth) }
        return months
    }

    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }

    private var nextMonth: Int {
        let month = currentMonth
        return month == 12 ? 1 : month + 1
    }

    private var shouldIncludeNextMonth: Bool {
        let calendar = Calendar.current
        let today = Date()
        guard let range = calendar.range(of: .day, in: .month, for: today) else { return false }
        let day = calendar.component(.day, from: today)
        let remainingDays = range.count - day
        return remainingDays <= 6
    }
}

#Preview {
    HomeLandingView()
        .environmentObject(TaskStore())
}
