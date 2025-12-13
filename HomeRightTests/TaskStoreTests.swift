import XCTest
@testable import HomeRight

@MainActor
final class TaskStoreTests: XCTestCase {
    func testMonthlyStatusIsScopedPerMonth() {
        let store = TaskStore()
        guard let task = ChecklistData.tasks.first(where: { $0.schedule == .monthly }) else {
            XCTFail("Expected at least one monthly task fixture")
            return
        }

        store.updateStatus(for: task, to: .complete, month: 1)

        XCTAssertEqual(store.progress(for: task, month: 1).status, .complete)
        XCTAssertEqual(store.progress(for: task, month: 2).status, .notStarted)
    }

    func testCostAndNotePersistPerMonth() {
        let store = TaskStore()
        guard let task = ChecklistData.tasks.first else {
            XCTFail("Missing fixtures")
            return
        }

        store.updateStatus(for: task, to: .complete, month: 1)
        store.updateCost(for: task, cost: 25, month: 1)
        store.updateNote(for: task, note: "Replaced filter", month: 1)

        let january = store.progress(for: task, month: 1)
        let february = store.progress(for: task, month: 2)

        XCTAssertEqual(january.status, .complete)
        XCTAssertEqual(january.cost, 25)
        XCTAssertEqual(january.note, "Replaced filter")

        XCTAssertEqual(february.status, .notStarted)
        XCTAssertNil(february.cost)
        XCTAssertEqual(february.note, "")
    }

    func testTotalsRespectSelectedYear() {
        let store = TaskStore()
        guard let task = ChecklistData.tasks.first else {
            XCTFail("Missing fixtures")
            return
        }

        store.selectedYear = 2024
        store.updateStatus(for: task, to: .complete, month: 1)
        store.updateCost(for: task, cost: 50, month: 1)

        XCTAssertEqual(store.completedCount, 1)
        XCTAssertEqual(store.totalCompletedCost, 50)

        store.selectedYear = 2025
        XCTAssertEqual(store.completedCount, 0)
        XCTAssertEqual(store.totalCompletedCost, 0)
    }

    func testSuggestedMonthlyBudgetIsPositive() {
        let store = TaskStore()
        XCTAssertGreaterThan(store.suggestedMonthlyBudget, 0)
    }
}
