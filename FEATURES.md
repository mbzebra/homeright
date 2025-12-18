# HomeRight (Home Maintenance) — Feature Specification

This document inventories the **implemented** features in this repository and describes them in a **prescriptive** way (what the app does, when it does it, and how it is expected to behave).

Source of truth is the SwiftUI code under `HomeRight/`.

---

## 1) Product Overview

**HomeRight** is a minimalist SwiftUI iOS app for tracking a recurring home-maintenance checklist with:

- A curated set of home maintenance tasks (stored locally in the app bundle).
- Month-by-month task tracking (status, date, cost, notes).
- Optional local notification reminders for scheduled tasks.
- iCloud Key-Value Store sync for progress and custom tasks.

Primary entry point is `HomeRight/HomeMaintenanceApp.swift`.

---

## 2) Screens & Navigation (User Flows)

### 2.1 Launch experience

**Launch screen**
- The iOS launch screen displays the app name “HomeRight”.
- Implemented in `HomeRight/LaunchScreen.storyboard`.

**In-app splash screen**
- On app start, a 1-second splash is shown with a house icon and “Prepping your upkeep plan…”.
- The splash transitions to the main experience with an ease-out animation (~0.4s).
- Implemented in `HomeRight/HomeMaintenanceApp.swift` and `HomeRight/Views/SplashView.swift`.

### 2.2 Home dashboard (`HomeLandingView`)

The home dashboard provides a “calm” overview and shortcuts.

**Header**
- Displays “Home Maintenance”, a greeting subtitle (“Good to see you”), and a profile placeholder icon.

**Hero card**
- Shows a time-of-day greeting (“Good morning/afternoon/evening”).
- Shows an urgency message based on the number of tasks currently marked “In Progress”.

**This month’s maintenance (preview)**
- Shows a “Needs attention” list: tasks with status “In Progress”.
- Shows an “Upcoming” list: tasks that are “Not Started” in the current month, and optionally the next month near month-end (last ~6 days).
- Shows a “Recently completed” list: tasks with status “Complete”.
- Provides a “View all” link to the full monthly list view.

**Shortcuts**
- Home Tasks → navigates to the month-by-month task list.
- Reminders → navigates to reminder settings.
- Service History → placeholder (“coming soon”).
- Find a Pro → placeholder (“coming soon”).

Implemented in `HomeRight/Views/HomeLandingView.swift`.

### 2.3 Month-by-month task list (`TaskListView`)

The Task List view is the core “work” screen. It is organized by month (January–December).

**Monthly sections**
- The view iterates through months `1...12`.
- A month section is shown only if the month has at least one task (base checklist tasks and/or custom tasks for that month).
- Each month section header shows:
  - Title: “{Month} Tasks”
  - Completion count: “X completed of Y”
  - Total cost for the month (only if > 0)
  - A plus (“Add task”) button to create a custom task for that month.

**Collapsed completed months**
- If all tasks in a month are “Complete”, the section collapses into a single “All tasks completed for now” row.
- The user can expand the month by tapping that row.

**Task cards**
- Each task shows:
  - A status icon (circle / clock / checkmark).
  - Title, detail (up to 2 lines), and optional cost.
  - A “Due soon” label when status is “In Progress”.
- Tapping a task navigates to Task Detail.

**Swipe actions (status updates)**
- Each task supports trailing swipe actions (no full swipe):
  - Set status to “Not Started”
  - Set status to “In Progress”
  - Set status to “Complete”
- Swiping changes status immediately for that month.

**Scroll behavior**
- On first appearance, the list scrolls to the current month.

Implemented in `HomeRight/Views/TaskListView.swift`.

### 2.4 Task detail & editing (`TaskDetailView`)

Task Detail is where users record completion info.

**Content**
- Shows the task detail description text.
- Shows a segmented status control: Not Started / In Progress / Complete.
- Shows “Date & Cost”:
  - Date picker (date-only)
  - Cost text field (decimal keypad)
  - Comments text editor
- Shows a “Schedule” chip at the bottom (e.g., Monthly, Quarterly, Spring, etc.).

**Persistence behavior**
- When the view appears, it loads stored progress (status, cost, note, date) for the task/month context.
- When the view disappears, it persists edits (status, cost, note, date).
- The “Submit” button explicitly persists edits and dismisses the view.
- Changing the status via the segmented control updates status immediately.

Implemented in `HomeRight/Views/TaskDetailView.swift`.

### 2.5 Add a custom task (per month)

From a month header in `TaskListView`, the user can add a custom task for that month.

**Data captured**
- Month (read-only display)
- Date (date picker; defaults to the 1st of the month in the selected year)
- Cost (decimal string parsed into `Decimal`)
- Task name (required; max 100 characters)
- Comments (optional; max 200 characters)

**Save rules**
- The “Save” action is disabled until Task name is non-empty after trimming.
- On Save, the custom task is created with schedule `.custom` and is stored under the chosen month.
- The custom task also receives an initial progress record (cost/note/date) for the current selected year + month.

Implemented in `HomeRight/Views/TaskListView.swift` and `HomeRight/Services/TaskStore.swift`.

---

## 3) Checklist Content (Built-in Tasks)

The app ships with a static list of checklist tasks.

**Task fields**
- `id`: stable UUID
- `title`: short task name
- `detail`: concise description
- `schedule`: cadence category

**Included task count**
- `ChecklistData.tasks` includes **22** built-in tasks.

Implemented in `HomeRight/Data/ChecklistData.swift` and modeled by `HomeRight/Models/Task.swift`.

---

## 4) Task Tracking & Progress Model

### 4.1 Task status

Each tracked task has one of three statuses:
- Not Started
- In Progress
- Complete

Defined in `HomeRight/Models/Task.swift` (`TaskStatus`).

### 4.2 Progress record (per task, month, year)

Each progress record (`TaskProgress`) can store:
- `status` (`TaskStatus`)
- `cost` (`Decimal?`)
- `note` (`String`)
- `date` (`Date?`)

Progress is keyed by:

```
{taskUUID}-{year}-{month}
```

This means a task can be tracked independently for each month and for each year.

Implemented in `HomeRight/Services/TaskStore.swift`.

### 4.3 Month completion & cost rollups

For a given month:
- `isMonthComplete(month)` is true only if all tasks for that month are marked “Complete”.
- `monthCost(month)` is the sum of all non-nil costs for tasks in that month.

Additionally, the store computes:
- `completedCount`: number of completed task-progress records in the selected year.
- `totalCompletedCost`: sum of costs of completed task-progress records in the selected year.
- `suggestedMonthlyBudget`: fixed value of `150`.
- `yearProgress`: ratio of months-with-tasks that are fully complete in the selected year.

Implemented in `HomeRight/Services/TaskStore.swift`.

---

## 5) Scheduling Logic (Which tasks appear in which month)

Tasks appear in months based on their `Schedule` value.

### 5.1 Built-in schedule mapping

The current mapping used by the task list (`TaskStore.schedule(_:matches:)`) is:

| Schedule | Months included |
|---|---|
| Monthly | 1–12 |
| Quarterly | 1, 4, 7, 10 |
| Annual | 1 |
| Spring | 3 |
| Summer | 6 |
| Fall | 9 |
| Winter | 12 |
| Seasonal | 3 |
| Custom | none (added explicitly to a chosen month) |

Implemented in `HomeRight/Services/TaskStore.swift`.

### 5.2 Custom tasks

Custom tasks:
- Are attached to a specific month (`customTasks[month]`).
- Do not participate in the built-in schedule mapping (their schedule is `.custom`).

Implemented in `HomeRight/Services/TaskStore.swift`.

---

## 6) Reminders & Notifications (Local)

The app supports **local notification reminders** via `UNUserNotificationCenter`.

### 6.1 Authorization & foreground presentation

**Authorization**
- On app launch, the app requests authorization for alerts, badges, and sounds.
- Implemented in `HomeRight/HomeMaintenanceApp.swift` (`AppDelegate`) and `HomeRight/Services/NotificationManager.swift`.

**Foreground presentation**
- Notifications are allowed to present as banner + list + sound even while the app is in the foreground.
- Implemented in `HomeRight/HomeMaintenanceApp.swift` (`UNUserNotificationCenterDelegate`).

### 6.2 Reminder settings screen (`ReminderSettingsView`)

**Reminder toggle**
- A single toggle controls whether reminders are enabled.
- When toggled ON:
  - Requests notification authorization.
  - Schedules reminders for all built-in checklist tasks.
  - Displays a status message indicating reminders are scheduled/active.
- When toggled OFF:
  - Removes all pending notification requests (pauses reminders).
  - Displays a “Reminders paused.” message.

Implemented in `HomeRight/Views/ReminderSettingsView.swift`.

**Important current behavior**
- The toggle state is derived from notification *authorization status* (`authorized` / `provisional`) on view appear.
- Disabling reminders only removes pending requests; it does not revoke authorization.
- Because the app also auto-registers reminders when authorized (see 6.4), reminders can be re-scheduled on a subsequent app launch/refresh even after toggling OFF.

### 6.3 Scheduling behavior (`NotificationManager`)

**Registration is “replace all”**
- When registering reminders, the manager first removes all pending requests and then re-adds reminders for the provided task list.

**Notification content**
- Title: task title
- Body: task detail
- Sound: default

**Trigger rules (repeats = true)**
- Monthly: day 1 at 9:00
- Quarterly: day 1 at 9:00 for months 1, 4, 7, 10 (one notification per quarter)
- Annual: Jan 15 at 9:00
- Spring: Mar 15 at 9:00
- Summer: Jun 15 at 9:00
- Fall: Sep 15 at 9:00
- Winter: Dec 1 at 9:00
- Seasonal: Mar 1 at 9:00
- Custom: no automatic reminders

Implemented in `HomeRight/Services/NotificationManager.swift`.

### 6.4 App-driven refresh

When the main content appears, the app calls `TaskStore.refreshNotifications()` which:
- Reads current authorization status.
- If authorized/provisional, registers reminders for built-in tasks.

Implemented in `HomeRight/HomeMaintenanceApp.swift` and `HomeRight/Services/TaskStore.swift`.

---

## 7) Persistence & Sync

The app stores progress and custom tasks in iCloud Key-Value Store (`NSUbiquitousKeyValueStore`).

### 7.1 What is synced

The following are encoded and synced:
- Task progress dictionary: `[String: TaskProgress]`
- Custom tasks by month (encoded as `[CustomTaskRecord]`)
- The `selectedYear` value

Implemented in `HomeRight/Services/TaskStore.swift`.

### 7.2 Sync mechanics

- On initialization, the store synchronizes and loads from cloud.
- The store listens for `NSUbiquitousKeyValueStore.didChangeExternallyNotification` and reloads data when it fires.
- Updates to progress/custom tasks/year trigger a save back to iCloud.

### 7.3 Entitlements

The project includes iCloud KVS entitlement:
- `com.apple.developer.ubiquity-kvstore-identifier`

Defined in `HomeRight/HomeRight.entitlements`.

---

## 8) Accessibility & UX Details

### 8.1 Keyboard and form UX

- Cost fields use a decimal keypad where applicable.
- Task Detail supports tap-to-dismiss keyboard and a “Done” keyboard toolbar action.
- Task Detail uses a persistent “Submit” bottom button to make saving explicit.

Implemented in `HomeRight/Views/TaskDetailView.swift`.

### 8.2 Accessibility identifiers (for UI testing)

The following identifiers are present:
- `ReminderSettingsView`
  - `enableRemindersToggle`
  - `notificationStatus`
- `TaskDetailView`
  - `costField`
  - `commentField`

Implemented in `HomeRight/Views/ReminderSettingsView.swift` and `HomeRight/Views/TaskDetailView.swift`.

---

## 9) Placeholders / Not Implemented (Yet)

The home screen includes shortcuts that currently navigate to placeholder text:
- Service History (“coming soon”)
- Find a Pro (“coming soon”)

Implemented in `HomeRight/Views/HomeLandingView.swift`.

Additionally, `TaskListView` contains UI components defined but not currently used in the view body:
- A segmented year selector with a progress overlay
- A “Completed/Spend” finance tile

Implemented in `HomeRight/Views/TaskListView.swift`.

---

## 10) Test Coverage (What exists in this repo)

**Unit tests**
- `TaskStoreTests` validates:
  - Status is scoped per month
  - Cost and note persist per month
  - Totals respect selected year
  - Suggested budget is positive

Located in `HomeRightTests/TaskStoreTests.swift`.

**UI tests**
- A UI test exists for enabling reminders and reading a status label.

Located in `HomeRightUITests/HomeRightUITests.swift`.

---

## 11) Operational Notes (Development / Configuration)

### 11.0 How to run (local)

- Open `HomeRight.xcodeproj` in Xcode.
- Select the `HomeRight` scheme and an iOS simulator/device.
- Build & run; the app requests notification permission on first launch.

### 11.1 Platform & tooling assumptions

- SwiftUI iOS app (Xcode project in `HomeRight.xcodeproj`).
- App uses generated Info.plist settings (see build setting `GENERATE_INFOPLIST_FILE = YES`).

### 11.2 Capabilities used

- **Local notifications**: requires user permission at runtime; notifications are scheduled locally on-device.
- **iCloud Key-Value Store**: requires iCloud capability and a valid app identifier entitlement configuration (`HomeRight/HomeRight.entitlements`).

### 11.3 Data storage & privacy characteristics (as implemented)

- No user accounts/auth flows are present in this repo.
- No remote network calls are present in this repo.
- Task progress and custom tasks are stored via iCloud KVS (and therefore can sync across the user’s devices logged into the same Apple ID).
