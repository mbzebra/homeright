import Foundation
import SwiftUI
import UIKit

struct TaskDetailView: View {
    let task: Task
    let month: Int?
    @EnvironmentObject private var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss
    @State private var status: TaskStatus = .notStarted
    @State private var costText: String = ""
    @State private var noteText: String = ""
    @FocusState private var isCostFieldFocused: Bool
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.detail)
                .font(.body)
                .foregroundStyle(.secondary)

            statusSection
            costSection

            Spacer()
            HStack {
                Label(task.schedule.displayName, systemImage: "calendar")
                Spacer()
            }
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding()
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            dismissKeyboard()
        }
        .onAppear(perform: loadProgress)
        .onDisappear(perform: persistEdits)
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                persistEdits()
                dismissKeyboard()
                dismiss()
            }) {
                Text("Submit")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.thinMaterial)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)
            Picker("Status", selection: $status) {
                ForEach(TaskStatus.allCases, id: \.self) { state in
                    Text(state.displayName).tag(state)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: status) { _, newValue in
                taskStore.updateStatus(for: task, to: newValue, month: month)
            }
        }
    }

    private var costSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Cost")
                    .font(.headline)
            }
            TextField("Enter amount (e.g. 125.00)", text: $costText)
                .keyboardType(.decimalPad)
                .textContentType(.none)
                .autocorrectionDisabled(true)
                .focused($isCostFieldFocused)
                .accessibilityIdentifier("costField")
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 6) {
                Text("Comments")
                    .font(.headline)
        TextEditor(text: $noteText)
            .frame(minHeight: 80)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled(true)
            .focused($isNoteFocused)
            .accessibilityIdentifier("commentField")
            }
        }
    }

    private func loadProgress() {
        let progress = taskStore.progress(for: task, month: month)
        status = progress.status
        if let cost = progress.cost {
            costText = NSDecimalNumber(decimal: cost).stringValue
        } else {
            costText = ""
        }
        noteText = progress.note
    }

    private func decimal(from text: String) -> Decimal? {
        Decimal(string: text.filter { "0123456789.".contains($0) })
    }

    private func persistEdits() {
        taskStore.updateStatus(for: task, to: status, month: month)
        taskStore.updateCost(for: task, cost: decimal(from: costText), month: month)
        taskStore.updateNote(for: task, note: noteText, month: month)
    }

    private func dismissKeyboard() {
        isCostFieldFocused = false
        isNoteFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    TaskDetailView(task: ChecklistData.tasks.first!, month: 1)
        .environmentObject(TaskStore())
}
