import Foundation

// Note: Core portfolio models (Resident, Unit, Lease, Payment, Expense)
// are defined in NetworkService.swift to avoid duplication.
// Extensions are added here for computed properties.

// MARK: - Resident Extensions
extension Resident: Identifiable {
    var fullName: String {
        "\(firstName ?? "") \(lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        let first = firstName?.prefix(1) ?? ""
        let last = lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Payment Extensions
extension Payment: Identifiable {
    var amount: Double {
        amountPaid ?? amountDue ?? 0
    }
    
    var paymentDateParsed: Date? {
        guard let dateStr = paymentDate else { return nil }
        return ISO8601DateFormatter().date(from: dateStr)
    }
    
    var isPast: Bool {
        guard let date = paymentDateParsed else { return true }
        return date < Date()
    }
    
    var residentName: String? { nil }
    var propertyAddress: String? { nil }
}

// MARK: - Unit Extensions
extension Unit: Identifiable {}

// MARK: - Lease Extensions
extension Lease: Identifiable {}

// MARK: - Expense Extensions
extension Expense: Identifiable {
    var expenseAmount: Double {
        amount ?? 0
    }
}
