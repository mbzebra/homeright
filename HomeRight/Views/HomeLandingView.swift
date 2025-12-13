import SwiftUI

struct HomeLandingView: View {
    @EnvironmentObject var taskStore: TaskStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    hero
                    taskPreview
                    actionGrid
                    recommended
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
                Text("Welcome back")
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title3.weight(.semibold))
            Text("\(remainingTasks) tasks to complete")
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

    private var taskPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: TaskListView().environmentObject(taskStore)) {
                    Text("View all")
                        .font(.subheadline.weight(.semibold))
                }
            }

            VStack(spacing: 8) {
                ForEach(previewTasks, id: \.id) { task in
                    NavigationLink(destination: TaskDetailView(task: task, month: nil)) {
                        HStack {
                            Image(systemName: statusIcon(for: task))
                                .foregroundStyle(statusColor(for: task))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(task.detail)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(task.schedule.displayName)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            taskStore.updateStatus(for: task, to: .notStarted)
                        } label: {
                            Image(systemName: "circle")
                        }
                        .tint(.gray)

                        Button {
                            taskStore.updateStatus(for: task, to: .inProgress)
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .tint(.orange)

                        Button {
                            taskStore.updateStatus(for: task, to: .complete)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .tint(.green)
                    }
                }
            }
        }
    }

    private var actionGrid: some View {
        let items: [(String, String, AnyView)] = [
            ("house.fill", "My Tasks", AnyView(TaskListView().environmentObject(taskStore))),
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
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .padding(10)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                            Text(item.1)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
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

    private var recommended: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended")
                .font(.headline)
            HStack(spacing: 12) {
                Image(systemName: "fan.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                    .padding()
                    .background(Color(.systemBlue).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule HVAC inspection")
                        .font(.subheadline.weight(.semibold))
                    Text("Spring is a good time")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var previewTasks: [Task] {
        Array(ChecklistData.tasks.prefix(3))
    }

    private var remainingTasks: Int {
        let completed = ChecklistData.tasks.filter { taskStore.progress(for: $0).status == .complete }.count
        return max(0, ChecklistData.tasks.count - completed)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func statusIcon(for task: Task) -> String {
        switch taskStore.progress(for: task).status {
        case .complete: return "checkmark.circle.fill"
        case .inProgress: return "clock.fill"
        case .notStarted: return "circle"
        }
    }

    private func statusColor(for task: Task) -> Color {
        switch taskStore.progress(for: task).status {
        case .complete: return .green
        case .inProgress: return .orange
        case .notStarted: return .gray
        }
    }

}

#Preview {
    HomeLandingView()
        .environmentObject(TaskStore())
}
