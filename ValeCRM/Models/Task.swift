import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case urgent
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending
    case inProgress = "in_progress"
    case completed
    case cancelled
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum TaskType: String, Codable, CaseIterable {
    case call
    case email
    case meeting
    case followUp = "follow_up"
    case inspection
    case showing
    case paperwork
    case other
    
    var displayName: String {
        switch self {
        case .call: return "Call"
        case .email: return "Email"
        case .meeting: return "Meeting"
        case .followUp: return "Follow Up"
        case .inspection: return "Inspection"
        case .showing: return "Showing"
        case .paperwork: return "Paperwork"
        case .other: return "Other"
        }
    }
}

struct CRMTask: Identifiable, Codable {
    var id: String
    var createdAt: Date
    var updatedAt: Date
    
    // Task Details
    var title: String
    var description: String?
    var type: TaskType
    var status: TaskStatus
    var priority: TaskPriority
    
    // Dates
    var dueDate: Date?
    var completedDate: Date?
    var reminderDate: Date?
    
    // Relationships
    var assignedTo: String?
    var assignedBy: String?
    var leadId: String?
    var clientId: String?
    var projectId: String?
    var propertyId: String?
    
    // Additional
    var tags: [String]
    var notes: String?

    var isCompleted: Bool {
        status == .completed
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return status != .completed && dueDate < Date()
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueSoon: Bool {
        guard let dueDate = dueDate else { return false }
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        return dueDate >= Date() && dueDate <= tomorrow
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, type, status, priority
        case dueDate, completedDate, reminderDate
        case assignedTo, assignedBy, leadId, clientId, projectId, propertyId
        case tags, notes
        case createdAt, updatedAt
    }
}

// Typealias for backward compatibility with existing code
typealias Task = CRMTask
