import Foundation

enum ProjectStatus: String, Codable, CaseIterable {
    case planning
    case active
    case onHold = "on_hold"
    case completed
    case cancelled
}

struct RehabProject: Identifiable, Codable {
    let id: UUID
    var propertyId: UUID
    var address: String
    var status: ProjectStatus
    var startDate: Date?
    var completionDate: Date?
    var totalBudget: Double
    var spentAmount: Double

    var remainingBudget: Double { totalBudget - spentAmount }
    var budgetUtilization: Double {
        guard totalBudget > 0 else { return 0 }
        return (spentAmount / totalBudget) * 100
    }
}
