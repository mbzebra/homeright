import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        NavigationStack {
            List {
                ForEach(taskStore.schedules, id: \.self) { schedule in
                    if let tasks = taskStore.groupedTasks[schedule] {
                        Section(header: sectionHeader(for: schedule)) {
                            ForEach(tasks) { task in
                                NavigationLink(destination: TaskDetailView(task: task)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.headline)
                                        Text(task.detail)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Home Upkeep")
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ReminderSettingsView()) {
                        Image(systemName: "bell.badge")
                    }
                }
            }
        }
    }

    private func sectionHeader(for schedule: Schedule) -> some View {
        HStack {
            Text(schedule.displayName)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .textCase(.none)
    }
}

#Preview {
    TaskListView()
        .environmentObject(TaskStore())
}
