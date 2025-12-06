import SwiftUI

struct TaskDetailView: View {
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.title)
                .font(.title2.weight(.semibold))
            Text(task.detail)
                .font(.body)
                .foregroundStyle(.secondary)
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
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    TaskDetailView(task: ChecklistData.tasks.first!)
}
