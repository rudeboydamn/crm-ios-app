import Foundation

enum ProjectStatus: String, Codable, CaseIterable {
    case planning
    case active
    case onHold = "on_hold"
    case completed
    case cancelled
}

struct RehabProject: Identifiable, Codable {
    var id: String = UUID().uuidString
    var propertyAddress: String = ""
    var propertyName: String = ""
    var status: ProjectStatus = .planning
    var purchaseDate: String?
    var sellDate: String?
    var measuredSqft: Double?
    var rehabType: String?
    
    // Purchase Costs
    var propertyPurchase: Double?
    var purchasePrice: Double? // Alias for propertyPurchase
    var homeInspection: Double?
    var appraisal: Double?
    var survey: Double?
    var lenderFees: Double?
    var purchaseClosingCosts: Double?
    var purchaseOther: Double?
    
    // Rehab Costs
    var totalContractor: Double?
    var totalMaterials: Double?
    
    // Holding Costs
    var mortgageInterest: Double?
    var investorMortgageInterest: Double?
    var propertyTaxes: Double?
    var insurance: Double?
    var totalUtilities: Double?
    var lawnCare: Double?
    var holdingOther: Double?
    
    // Selling Costs
    var salesRevenue: Double?
    var afterRepairValue: Double? // Alias for salesRevenue
    var brokerCommissionPercent: Double?
    var homeWarranty: Double?
    var buyerTermite: Double?
    var closingCostsBuyer: Double?
    var sellingClosingCosts: Double?
    
    // Other
    var bankServiceCharges: Double?
    var quickbooksPropertyName: String?
    var projectedROI: Double? // Add missing property
    
    // Calculated fields (from API)
    var totalPurchaseCosts: Double?
    var totalRehabCosts: Double?
    var totalHoldingCosts: Double?
    var totalSellingCosts: Double?
    var totalExpenses: Double?
    var netIncome: Double?
    var totalInvestment: Double?
    var roi: Double?
    
    var createdAt: String?
    var updatedAt: String?
    
    // Computed properties for UI
    var displayName: String {
        propertyName.isEmpty ? propertyAddress : propertyName
    }
    
    var budgetTotal: Double {
        (totalPurchaseCosts ?? 0) + (totalRehabCosts ?? 0) + (totalHoldingCosts ?? 0)
    }
    
    var totalBudget: Double {
        get {
            budgetTotal
        }
        set {
            // This setter is here for backward compatibility but doesn't actually store
            // The value is always computed from the cost components
        }
    }
    
    var totalSpent: Double {
        if let totalExpenses = totalExpenses {
            return totalExpenses
        }
        return (totalPurchaseCosts ?? 0) + (totalRehabCosts ?? 0) + (totalHoldingCosts ?? 0) + (totalSellingCosts ?? 0)
    }
    
    var remainingBudget: Double {
        max(totalBudget - totalSpent, 0)
    }
    
    var budgetUtilization: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalSpent / totalBudget) * 100
    }
    
    var roiValue: Double {
        roi ?? 0
    }
    
    var projectedProfit: Double {
        let revenue = afterRepairValue ?? salesRevenue ?? 0
        let costs = totalSpent
        return revenue - costs
    }
    
    var startDate: Date? {
        guard let purchaseDate = purchaseDate else { return nil }
        return RehabProject.iso8601.date(from: purchaseDate)
    }
    
    var completionDate: Date? {
        guard let sellDate = sellDate else { return nil }
        return RehabProject.iso8601.date(from: sellDate)
    }
    
    var statusDisplay: String {
        switch status {
        case .planning: return "Planning"
        case .active: return "Active"
        case .onHold: return "On Hold"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    private static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    enum CodingKeys: String, CodingKey {
        case id
        case status
        case propertyAddress = "property_address"
        case propertyName = "property_name"
        case purchaseDate = "purchase_date"
        case sellDate = "sell_date"
        case measuredSqft = "measured_sqft"
        case rehabType = "rehab_type"
        case propertyPurchase = "property_purchase"
        case purchasePrice = "purchase_price"
        case homeInspection = "home_inspection"
        case appraisal
        case survey
        case lenderFees = "lender_fees"
        case purchaseClosingCosts = "purchase_closing_costs"
        case purchaseOther = "purchase_other"
        case totalContractor = "total_contractor"
        case totalMaterials = "total_materials"
        case mortgageInterest = "mortgage_interest"
        case investorMortgageInterest = "investor_mortgage_interest"
        case propertyTaxes = "property_taxes"
        case insurance
        case totalUtilities = "total_utilities"
        case lawnCare = "lawn_care"
        case holdingOther = "holding_other"
        case salesRevenue = "sales_revenue"
        case afterRepairValue = "after_repair_value"
        case brokerCommissionPercent = "broker_commission_percent"
        case homeWarranty = "home_warranty"
        case buyerTermite = "buyer_termite"
        case closingCostsBuyer = "closing_costs_buyer"
        case sellingClosingCosts = "selling_closing_costs"
        case bankServiceCharges = "bank_service_charges"
        case quickbooksPropertyName = "quickbooks_property_name"
        case projectedROI = "projected_roi"
        case totalPurchaseCosts = "total_purchase_costs"
        case totalRehabCosts = "total_rehab_costs"
        case totalHoldingCosts = "total_holding_costs"
        case totalSellingCosts = "total_selling_costs"
        case totalExpenses = "total_expenses"
        case netIncome = "net_income"
        case totalInvestment = "total_investment"
        case roi
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
