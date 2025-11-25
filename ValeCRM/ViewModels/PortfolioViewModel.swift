import Foundation
import Combine
import Supabase

final class PortfolioViewModel: ObservableObject {
    @Published var dashboardMetrics: PortfolioDashboardMetrics?
    @Published var properties: [Property] = []
    @Published var units: [Unit] = []
    @Published var residents: [Resident] = []
    @Published var leases: [Lease] = []
    @Published var mortgages: [Mortgage] = []
    @Published var expenses: [Expense] = []
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let propertyService = PropertyDatabaseService.shared
    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    func fetchPortfolioData() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                // Fetch properties
                let fetchedProperties = try await propertyService.fetchAll()
                
                // Fetch portfolio dashboard metrics (may need RPC function)
                let dashboard: PortfolioDashboardMetrics = try await supabase.database
                    .rpc("get_portfolio_dashboard")
                    .execute()
                    .value
                
                // Fetch related entities
                let fetchedUnits: [Unit] = try await supabase.database
                    .from("units")
                    .select()
                    .execute()
                    .value
                
                let fetchedResidents: [Resident] = try await supabase.database
                    .from("residents")
                    .select()
                    .execute()
                    .value
                
                let fetchedLeases: [Lease] = try await supabase.database
                    .from("leases")
                    .select()
                    .execute()
                    .value
                
                let fetchedMortgages: [Mortgage] = try await supabase.database
                    .from("mortgages")
                    .select()
                    .execute()
                    .value
                
                let fetchedExpenses: [Expense] = try await supabase.database
                    .from("expenses")
                    .select()
                    .execute()
                    .value
                
                let fetchedPayments: [Payment] = try await supabase.database
                    .from("payments")
                    .select()
                    .execute()
                    .value
                
                await MainActor.run {
                    self.dashboardMetrics = dashboard
                    self.properties = fetchedProperties
                    self.units = fetchedUnits
                    self.residents = fetchedResidents
                    self.leases = fetchedLeases
                    self.mortgages = fetchedMortgages
                    self.expenses = fetchedExpenses
                    self.payments = fetchedPayments
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = SupabaseError.map(error).localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // Helper computed properties
    var totalProperties: Int {
        properties.count
    }
    
    var occupiedUnits: Int {
        residents.count
    }
    
    var totalUnits: Int {
        dashboardMetrics?.totalUnits ?? 0
    }
    
    var occupancyRate: Double {
        dashboardMetrics?.occupancyRate ?? 0
    }
    
    var currentMonthPayments: [Payment] {
        let calendar = Calendar.current
        let now = Date()
        
        return payments.filter { payment in
            guard let dueDate = ISO8601DateFormatter().date(from: payment.dueDate) else {
                return false
            }
            return calendar.isDate(dueDate, equalTo: now, toGranularity: .month)
        }
    }
    
    var paidPayments: [Payment] {
        currentMonthPayments.filter { $0.status == "paid" }
    }
    
    var unpaidPayments: [Payment] {
        currentMonthPayments.filter { $0.status != "paid" }
    }
}
