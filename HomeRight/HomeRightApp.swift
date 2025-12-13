//
//  HomeRightApp.swift
//  HomeRight
//
//  Created by Mariswaran Balasubramanian on 12/5/25.
//

import SwiftUI

struct HomeRightApp: View {
    @StateObject private var taskStore = TaskStore()

    var body: some View {
        TaskListView()
            .environmentObject(taskStore)
    }
}

#Preview {
    HomeRightApp()
}
