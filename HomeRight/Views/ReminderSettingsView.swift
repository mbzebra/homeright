import SwiftUI

struct ReminderSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var statusMessage = ""

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Enable reminders", systemImage: "bell")
                }
                .accessibilityIdentifier("enableRemindersToggle")
                .onChange(of: notificationsEnabled, perform: handleToggle)
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("notificationStatus")
                }
            }
            Section("Design Notes") {
                Text("Minimalist layout keeps focus on the task at hand and pairs each reminder with concise notes to reduce cognitive load.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
        }
        .navigationTitle("Reminders")
        .onAppear { refreshStatus() }
    }

    private func handleToggle(_ isOn: Bool) {
        if isOn {
            NotificationManager.shared.requestAuthorization()
            _Concurrency.Task { await NotificationManager.shared.registerReminders(for: ChecklistData.tasks) }
            statusMessage = "Scheduled reminders for every cadence."
        } else {
            _Concurrency.Task {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
            statusMessage = "Reminders paused."
        }
    }

    private func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
                statusMessage = notificationsEnabled ? "Reminders are active." : "Enable to receive subtle nudges."
            }
        }
    }
}

#Preview {
    ReminderSettingsView()
}
