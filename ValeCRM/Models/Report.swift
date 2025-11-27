import Foundation

enum ReportType: String, Codable, CaseIterable {
    case leadsOverview = "leads_overview"
    case salesPipeline = "sales_pipeline"
    case projectsPerformance = "projects_performance"
    case portfolioAnalysis = "portfolio_analysis"
    case financialSummary = "financial_summary"
    case activityLog = "activity_log"
    
    var displayName: String {
        switch self {
        case .leadsOverview: return "Leads Overview"
        case .salesPipeline: return "Sales Pipeline"
        case .projectsPerformance: return "Projects Performance"
        case .portfolioAnalysis: return "Portfolio Analysis"
        case .financialSummary: return "Financial Summary"
        case .activityLog: return "Activity Log"
        }
    }
}

enum ReportPeriod: String, Codable, CaseIterable {
    case today
    case week
    case month
    case quarter
    case year
    case custom
    
    var displayName: String {
        rawValue.capitalized
    }
}

struct ReportDashboardMetrics: Codable {
    // Leads Metrics
    var totalLeads: Int?
    var newLeads: Int?
    var qualifiedLeads: Int?
    var hotLeads: Int?
    var convertedLeads: Int?
    var conversionRate: Double?
    
    // Projects Metrics
    var totalProjects: Int?
    var activeProjects: Int?
    var completedProjects: Int?
    var totalProjectValue: Double?
    var totalProjectBudget: Double?
    var totalProjectSpent: Double?
    var averageROI: Double?
    
    // Portfolio Metrics
    var totalProperties: Int?
    var totalUnits: Int?
    var occupiedUnits: Int?
    var vacantUnits: Int?
    var occupancyRate: Double?
    var totalPortfolioValue: Double?
    var totalMonthlyRent: Double?
    var totalRentCollected: Double?
    var totalRentDue: Double?
    var collectionRate: Double?
    
    // Financial Metrics
    var monthlyRevenue: Double?
    var monthlyExpenses: Double?
    var netCashFlow: Double?
    var totalRevenue: Double?
    var totalExpenses: Double?
    var netIncome: Double?
    var profitMargin: Double?
    
    // Activity Metrics
    var totalTasks: Int?
    var pendingTasks: Int?
    var inProgressTasks: Int?
    var overdueTasks: Int?
    var completedTasks: Int?
    var upcomingMeetings: Int?
    
    // Client Metrics
    var totalClients: Int?
    var activeClients: Int?
    var newClients: Int?
    
    // Timestamp
    var generatedAt: String?
}

struct LeadSourceMetric: Identifiable, Codable {
    var id: String { source }
    var source: String
    var count: Int
    var percentage: Double
    var conversionRate: Double
}

struct LeadStatusMetric: Identifiable, Codable {
    var id: String { status }
    var status: String
    var count: Int
    var percentage: Double
    var averageAge: Double // days
}

struct MonthlyMetric: Identifiable, Codable {
    var id: String { month }
    var month: String
    var leads: Int
    var conversions: Int
    var revenue: Double
    var expenses: Double
    var profit: Double
}

struct ReportData: Codable {
    var period: ReportPeriod
    var startDate: Date
    var endDate: Date
    var generatedAt: Date
    
    var dashboard: ReportDashboardMetrics
    var leadSources: [LeadSourceMetric]
    var leadStatuses: [LeadStatusMetric]
    var monthlyData: [MonthlyMetric]
}
