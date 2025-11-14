import Foundation

enum LeadSource: String, Codable, CaseIterable {
    case webForm = "web_form"
    case phoneCall = "phone_call"
    case sms
    case directMail = "direct_mail"
    case drivingForDollars = "driving_for_dollars"
    case referral
    case other
}

enum LeadStatus: String, Codable, CaseIterable {
    case new
    case contacted
    case qualified
    case appointmentScheduled = "appointment_scheduled"
    case offerMade = "offer_made"
    case contract
    case closed
    case lost
}

enum LeadPriority: String, Codable, CaseIterable {
    case hot
    case warm
    case cold
}

struct Lead: Identifiable, Codable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var hubspotId: String?

    var firstName: String
    var lastName: String
    var email: String
    var phone: String

    var source: LeadSource
    var status: LeadStatus
    var priority: LeadPriority
    var tags: [String]

    var propertyAddress: String
    var propertyCity: String
    var propertyState: String
    var propertyZip: String

    var askingPrice: Double?
    var offerAmount: Double?
    var arv: Double?

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
