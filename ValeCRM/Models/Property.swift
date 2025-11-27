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
    let id: String
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?  // Matches database zip_code -> zipCode
    var propertyType: String?
    var status: String?
    var purchasePrice: Double?
    var marketValue: Double?  // Matches database market_value
    var totalUnits: Int?
    var propertyTaxAnnual: Double?
    var insuranceAnnual: Double?
    var hoaMonthly: Double?
    var createdAt: String?
    
    // Computed properties for convenience
    var zip: String? { zipCode }
    var currentValue: Double? { marketValue }
    var monthlyRent: Double? { nil }  // Would come from units
    var monthlyExpenses: Double? { nil }  // Would come from expenses

    var monthlyCashFlow: Double { (monthlyRent ?? 0) - (monthlyExpenses ?? 0) }
    var annualCashFlow: Double { monthlyCashFlow * 12 }
    var roi: Double {
        guard let purchase = purchasePrice, purchase > 0 else { return 0 }
        return (annualCashFlow / purchase) * 100
    }
}
