import Foundation
import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var editingTask: Task? = nil
    @State private var editingMonth: Int? = nil
    @State private var costText: String = ""
    @State private var noteText: String = ""
    @State private var editingStatus: TaskStatus = .notStarted
    @FocusState private var isCostFieldFocused: Bool
    @FocusState private var isNoteFocused: Bool
    private let currentMonth = Calendar.current.component(.month, from: Date())
    @State private var expandedMonths: Set<Int> = []
    @State private var showingNewTaskSheet = false
    @State private var newTaskMonth: Int = 1
    @State private var newTaskTitle: String = ""
    @State private var newTaskDetail: String = ""

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                ForEach(1...12, id: \.self) { month in
                    let tasks = taskStore.tasks(in: month)
                    if !tasks.isEmpty {
                        let allComplete = tasks.allSatisfy { taskStore.progress(for: $0, month: month).status == .complete }
                        Section(header: sectionHeader(for: month, tasks: tasks, taskStore: taskStore, onAdd: {
                            newTaskMonth = month
                            newTaskTitle = ""
                            newTaskDetail = ""
                            showingNewTaskSheet = true
                        })) {
                            if allComplete && !expandedMonths.contains(month) {
                                Button {
                                    expandedMonths.insert(month)
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.green)
                                        Text("All tasks completed for now")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ForEach(tasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task, month: month)) {
                                        TaskCard(
                                            task: task,
                                            status: taskStore.progress(for: task, month: month).status,
                                            statusPill: statusPill(for: task, month: month),
                                            schedulePill: schedulePill(for: task),
                                            cost: taskStore.progress(for: task, month: month).cost,
                                            onSwipeStatus: { _ in }
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            taskStore.updateStatus(for: task, to: .notStarted, month: month)
                                        } label: {
                                            Image(systemName: "circle")
                                        }
                                        .tint(.gray)

                                        Button {
                                            taskStore.updateStatus(for: task, to: .inProgress, month: month)
                                        } label: {
                                            Image(systemName: "clock.arrow.circlepath")
                                        }
                                        .tint(.orange)

                                        Button {
                                            taskStore.updateStatus(for: task, to: .complete, month: month)
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                }
                            }
                        }
                        .id(month)
                        .textCase(nil)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(.systemGroupedBackground))
                    }
                }
            }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(currentMonth, anchor: .top)
                    }
                }
            }
        }
        .sheet(item: $editingTask, content: statusSheet)
        .sheet(isPresented: $showingNewTaskSheet) {
            newTaskSheet
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 12)
        }
    }

    private var yearSelector: some View {
        let progress = taskStore.yearProgress
        let years = taskStore.availableYears
        let selectedIndex = years.firstIndex(of: taskStore.selectedYear) ?? 0
        return ZStack {
            Capsule()
                .fill(Color(.tertiarySystemFill))
            GeometryReader { geo in
                let segmentWidth = geo.size.width / CGFloat(max(years.count, 1))
                let offsetX = segmentWidth * CGFloat(selectedIndex)
                let fillWidth = segmentWidth * CGFloat(max(0, min(1, progress)))

                LinearGradient(
                    colors: [.blue.opacity(0.7), .green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: fillWidth == 0 ? 1 : fillWidth, height: geo.size.height)
                .opacity(progress > 0 ? 0.85 : 0)
                .offset(x: offsetX)
                .mask(
                    RoundedRectangle(cornerRadius: geo.size.height / 2)
                        .frame(width: segmentWidth, height: geo.size.height)
                        .offset(x: offsetX)
                )
                .animation(.easeInOut(duration: 0.3), value: progress)
                .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            }
            Picker("Year", selection: $taskStore.selectedYear) {
                ForEach(years, id: \.self) { year in
                    Text("\(year)").tag(year)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(height: 36)
        .padding(.vertical, 1)
    }

    private var financeTile: some View {
        HStack(spacing: 12) {
            MetricPill(
                title: "Completed",
                value: "\(taskStore.completedCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            MetricPill(
                title: "Spend",
                value: formattedCost(taskStore.totalCompletedCost),
                icon: "dollarsign.circle",
                color: .blue
            )
        }
    }

    private func formattedCost(_ cost: Decimal) -> String {
        let number = NSDecimalNumber(decimal: cost)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: number) ?? "$0"
    }

    private func statusPill(for task: Task, month: Int) -> AnyView {
        let status = taskStore.progress(for: task, month: month).status
        let color: Color
        switch status {
        case .notStarted: color = .gray
        case .inProgress: color = .orange
        case .complete: color = .green
        }
        return AnyView(
            Text(status.displayName)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(Capsule())
        )
    }

    private func schedulePill(for task: Task) -> AnyView {
        let (label, color): (String, Color)
        switch task.schedule {
        case .monthly:
            label = "Monthly"; color = .blue
        case .quarterly:
            label = "Quarterly"; color = .purple
        case .annual:
            label = "Yearly"; color = .teal
        case .spring, .summer, .fall, .winter, .seasonal:
            label = "Seasonal"; color = .indigo
        case .custom:
            label = "Custom"; color = .gray
        }

        return AnyView(
            Text(label)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.12))
                .foregroundStyle(color)
                .clipShape(Capsule())
        )
    }

    private func monthName(from month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        let monthName = formatter.monthSymbols[max(0, min(11, month - 1))]
        return "\(monthName) \(taskStore.selectedYear)"
    }

    private func statusSheet(for task: Task) -> some View {
        NavigationStack {
            Form {
                Section("Status") {
                    Picker("Status", selection: $editingStatus) {
                        ForEach(TaskStatus.allCases, id: \.self) { state in
                            Text(state.displayName).tag(state)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Cost") {
                    TextField("Enter amount", text: $costText)
                        .keyboardType(.decimalPad)
                        .textContentType(.none)
                        .focused($isCostFieldFocused)
                }

                Section("Comments") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                        .focused($isNoteFocused)
                }
            }
            .navigationTitle(task.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        taskStore.updateStatus(for: task, to: editingStatus, month: editingMonth)
                        taskStore.updateCost(for: task, cost: Decimal(string: costText), month: editingMonth)
                        taskStore.updateNote(for: task, note: noteText, month: editingMonth)
                        editingTask = nil
                        editingMonth = nil
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingTask = nil; editingMonth = nil }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    editingTask = nil
                    editingMonth = nil
                }
            }
        }
        .onChange(of: editingStatus) { newValue in
            if newValue == .complete {
                DispatchQueue.main.async {
                    isCostFieldFocused = true
                }
            } else {
                isCostFieldFocused = false
            }
        }
    }

    private var newTaskSheet: some View {
        NavigationStack {
            Form {
                Section("Month") {
                    Text(monthName(from: newTaskMonth))
                        .font(.subheadline.weight(.semibold))
                }

                Section("Task name") {
                    TextField("Enter task name", text: $newTaskTitle)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(true)
                        .onChange(of: newTaskTitle) { newValue in
                            if newValue.count > 100 {
                                newTaskTitle = String(newValue.prefix(100))
                            }
                        }
                    Text("\(newTaskTitle.count)/100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Details") {
                    TextEditor(text: $newTaskDetail)
                        .frame(minHeight: 120)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(true)
                        .onChange(of: newTaskDetail) { newValue in
                            if newValue.count > 200 {
                                newTaskDetail = String(newValue.prefix(200))
                            }
                        }
                    Text("\(newTaskDetail.count)/200")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNewTaskSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let detail = newTaskDetail.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty else { return }
                        taskStore.addCustomTask(title: title, detail: detail, month: newTaskMonth)
                        showingNewTaskSheet = false
                    }
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Components

private struct MetricPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.weight(.semibold))
            }
            Spacer()
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private func sectionHeader(for month: Int, tasks: [Task], taskStore: TaskStore, onAdd: @escaping () -> Void) -> some View {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    let monthName = formatter.monthSymbols[max(0, min(11, month - 1))]
    let total = tasks.count
    let completed = tasks.filter { taskStore.progress(for: $0, month: month).status == .complete }.count
    let monthCost = tasks
        .compactMap { taskStore.progress(for: $0, month: month).cost }
        .reduce(Decimal(0), +)
    let allDone = total > 0 && completed == total
    let titleColor: Color = allDone ? .green : .primary
    let badgeBackground = Color(.tertiarySystemFill)

    return VStack(alignment: .leading, spacing: 8) {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(monthName) Tasks")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(titleColor)
                    .padding(.top, 4)
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                        Text("\(completed) completed of \(total)")
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(badgeBackground)
                    .clipShape(Capsule())

                    if monthCost > 0 {
                        Text("Total: \(formattedCost(monthCost))")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(badgeBackground)
                            .clipShape(Capsule())
                    }
                }
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .padding(.top, 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add task for \(monthName)")
        }
    }
}

private func formattedCost(_ cost: Decimal) -> String {
    let number = NSDecimalNumber(decimal: cost)
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    return formatter.string(from: number) ?? "$0"
}

private struct TaskCard: View {
    let task: Task
    let status: TaskStatus
    let statusPill: AnyView
    let schedulePill: AnyView
    let cost: Decimal?
    let onSwipeStatus: (TaskStatus) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .opacity(status == .complete ? 0.7 : 1)
                    Spacer()
                    if let cost {
                        Text(formatCost(cost))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(task.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if status == .inProgress {
                    Text("Due soon")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: status == .complete ? Color.black.opacity(0.02) : Color.black.opacity(0.05),
                radius: status == .complete ? 2 : 6,
                x: 0, y: status == .complete ? 1 : 3)
        .contentShape(Rectangle())
    }

    private var statusIcon: some View {
        let color: Color
        switch status {
        case .notStarted: color = .gray
        case .inProgress: color = .orange
        case .complete: color = .green
        }
        let symbol: String
        switch status {
        case .complete: symbol = "checkmark.circle.fill"
        case .inProgress: symbol = "clock"
        case .notStarted: symbol = "circle"
        }
        return Image(systemName: symbol)
            .font(.title3)
            .foregroundStyle(color)
    }

    private func formatCost(_ cost: Decimal) -> String {
        let number = NSDecimalNumber(decimal: cost)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: number) ?? "$0"
    }
}
#Preview {
    TaskListView()
        .environmentObject(TaskStore())
}
