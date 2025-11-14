import Foundation

enum PropertyType: String, Codable, CaseIterable {
    case singleFamily = "single_family"
    case multiFamily = "multi_family"
    case condo
    case townhouse
    case land
    case commercial
}

enum PropertyStatus: String, Codable, CaseIterable {
    case owned
    case forSale = "for_sale"
    case underContract = "under_contract"
    case rehabbing
    case rental
}

struct Property: Identifiable, Codable {
    let id: UUID
    var address: String
    var city: String
    var state: String
    var zip: String
    var propertyType: PropertyType
    var status: PropertyStatus
    var purchasePrice: Double?
    var currentValue: Double?
    var monthlyRent: Double?
    var monthlyExpenses: Double?

    var monthlyCashFlow: Double { (monthlyRent ?? 0) - (monthlyExpenses ?? 0) }
    var annualCashFlow: Double { monthlyCashFlow * 12 }
    var roi: Double {
        guard let purchase = purchasePrice, purchase > 0 else { return 0 }
        return (annualCashFlow / purchase) * 100
    }
}
