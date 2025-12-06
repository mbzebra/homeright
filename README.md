# Home Maintenance iOS App

A minimalist SwiftUI app that turns the provided home maintenance checklist into a structured, reminder-friendly experience. It keeps the interface calm and simple while offering strong notification support so seasonal and recurring chores stay on schedule.

## Features
- Organized checklist by cadence (monthly, quarterly, seasonal, and annual) with concise task detail screens.
- Push notification scheduling for every task using `UNUserNotificationCenter` and an app delegate bridge for lifecycle awareness.
- Lightweight reminder controls that let users toggle notifications with immediate feedback.
- Modern SwiftUI design with ample whitespace, neutral typography, and subtle system materials.

## Project Structure
- `HomeMaintenanceApp.swift`: App entry point, environment setup, and notification delegate wiring.
- `Models/`: Task and schedule types.
- `Data/`: Static checklist data derived from the provided PDF.
- `Services/`: Notification helper and observable task store.
- `Views/`: Minimal SwiftUI screens for list, detail, and reminder controls.

## Running
1. Open the `HomeMaintenanceApp` folder in Xcode 15+.
2. Ensure the bundle identifier is configured for push notifications in your Apple Developer account if you want to test on device.
3. Build and run on an iOS 17+ simulator or device. The first launch will request notification permission and schedule reminders automatically when enabled.
