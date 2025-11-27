import Foundation
import Combine

final class PortfolioViewModel: ObservableObject {
    @Published var dashboardMetrics: PortfolioDashboardMetrics?
    @Published var properties: [Property] = []
    @Published var units: [Unit] = []
    @Published var residents: [Resident] = []
    @Published var leases: [Lease] = []
    @Published var expenses: [Expense] = []
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    func fetchPortfolioData() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchPortfolio()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    self.dashboardMetrics = response.data.dashboard
                    self.properties = response.data.properties
                    self.units = response.data.units
                    self.residents = response.data.residents
                    self.leases = response.data.leases
                    self.expenses = response.data.expenses
                    self.payments = response.data.payments
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    
    func createProperty(_ property: Property) {
        networkService.createProperty(property)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] newProperty in
                    self?.properties.append(newProperty)
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProperty(_ property: Property) {
        networkService.updateProperty(property)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] updatedProperty in
                    if let index = self?.properties.firstIndex(where: { $0.id == updatedProperty.id }) {
                        self?.properties[index] = updatedProperty
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteProperty(id: String) {
        networkService.deleteProperty(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.properties.removeAll { $0.id == id }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var totalProperties: Int {
        properties.count
    }
    
    var occupiedUnits: Int {
        dashboardMetrics?.occupiedUnits ?? residents.filter { ($0.status ?? "").lowercased() == "active" }.count
    }
    
    var totalUnits: Int {
        dashboardMetrics?.totalUnits ?? units.count
    }
    
    var occupancyRate: Double {
        dashboardMetrics?.occupancyRate ?? (totalUnits > 0 ? Double(occupiedUnits) / Double(totalUnits) * 100 : 0)
    }
    
    var totalPortfolioValue: Double {
        dashboardMetrics?.totalPortfolioValue ?? properties.compactMap { $0.marketValue }.reduce(0, +)
    }
    
    var totalMonthlyRent: Double {
        dashboardMetrics?.totalMonthlyIncome ?? units.compactMap { $0.monthlyRent }.reduce(0, +)
    }
    
    var totalExpenses: Double {
        dashboardMetrics?.totalMonthlyExpenses ?? expenses.reduce(0) { $0 + ($1.amount ?? 0) }
    }
    
    var netCashFlow: Double {
        dashboardMetrics?.netMonthlyCashFlow ?? (totalMonthlyRent - totalExpenses)
    }
    
    var collectionRate: Double {
        dashboardMetrics?.collectionRate ?? 0
    }
    
    var currentMonthPayments: [Payment] {
        let calendar = Calendar.current
        let now = Date()
        
        return payments.filter { payment in
            guard let dateStr = payment.paymentDate,
                  let paymentDate = ISO8601DateFormatter().date(from: dateStr) else { return false }
            return calendar.isDate(paymentDate, equalTo: now, toGranularity: .month)
        }
    }
    
    var paidPayments: [Payment] {
        currentMonthPayments.filter { ($0.status ?? "").lowercased() == "paid" || ($0.status ?? "").lowercased() == "completed" }
    }
    
    var unpaidPayments: [Payment] {
        currentMonthPayments.filter { ($0.status ?? "").lowercased() != "paid" && ($0.status ?? "").lowercased() != "completed" }
    }
}
