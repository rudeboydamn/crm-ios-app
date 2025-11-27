import Foundation

enum CommunicationType: String, Codable, CaseIterable {
    case call
    case email
    case sms
    case meeting
    case note
    
    var displayName: String {
        switch self {
        case .call: return "Call"
        case .email: return "Email"
        case .sms: return "SMS"
        case .meeting: return "Meeting"
        case .note: return "Note"
        }
    }
    
    var iconName: String {
        switch self {
        case .call: return "phone.fill"
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .meeting: return "person.2.fill"
        case .note: return "note.text"
        }
    }
}

// MARK: - Communication Contact
struct CommunicationContact: Identifiable, Codable {
    let id: String
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var company: String?
    var type: String?  // lead, client, vendor
    var status: String?
    var source: String?
    var tags: [String]?
    var notes: String?
    var createdAt: String?
    
    var fullName: String {
        "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        let first = firstName?.prefix(1) ?? ""
        let last = lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Communication Template
struct CommunicationTemplate: Identifiable, Codable {
    let id: String
    var name: String
    var type: String  // email, sms
    var subject: String?
    var body: String
    var category: String?
    var isActive: Bool?
    var createdAt: String?
}

enum CommunicationDirection: String, Codable {
    case inbound
    case outbound
}

struct Communication: Identifiable, Codable {
    var id: String
    var createdAt: Date?
    var updatedAt: Date?
    
    // Communication Details
    var type: CommunicationType
    var direction: CommunicationDirection?
    var subject: String?
    var content: String?
    var notes: String?
    var duration: Int? // in minutes for calls
    var status: String?
    var date: Date?
    var contactName: String?
    
    // Relationships
    var userId: String?
    var leadId: String?
    var clientId: String?
    var projectId: String?
    var propertyId: String?
    var contactId: String?
    
    // Metadata
    var fromAddress: String?
    var toAddress: String?
    var attachments: [String]?
    var tags: [String]?
    
    var durationDisplay: String? {
        guard let duration = duration else { return nil }
        return "\(duration) min"
    }
    
    var displayTitle: String {
        if let subject = subject, !subject.isEmpty {
            return subject
        }
        return "\(type.displayName) - \(direction == .inbound ? "Received" : "Sent")"
    }
}
