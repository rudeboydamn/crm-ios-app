import Foundation
import Combine
import Supabase

final class PropertyViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedType: String?
    @Published var selectedStatus: String?
    
    private let databaseService = PropertyDatabaseService.shared
    private let realtimeManager = RealtimeManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?
    
    var filteredProperties: [Property] {
        properties.filter { property in
            let matchesSearch = searchText.isEmpty ||
                property.address.localizedCaseInsensitiveContains(searchText) ||
                property.city.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedType == nil || property.propertyType == selectedType
            let matchesStatus = selectedStatus == nil || property.status == selectedStatus
            
            return matchesSearch && matchesType && matchesStatus
        }
    }
    
    var totalPortfolioValue: Double {
        properties.compactMap { $0.currentValue }.reduce(0, +)
    }
    
    var totalMonthlyIncome: Double {
        properties.compactMap { $0.monthlyRent }.reduce(0, +)
    }
    
    var totalMonthlyExpenses: Double {
        properties.compactMap { $0.monthlyExpenses }.reduce(0, +)
    }
    
    var netMonthlyCashFlow: Double {
        totalMonthlyIncome - totalMonthlyExpenses
    }
    
    var averageROI: Double {
        let rois = properties.map { $0.roi }.filter { $0 > 0 }
        guard !rois.isEmpty else { return 0 }
        return rois.reduce(0, +) / Double(rois.count)
    }
    
    var rentalProperties: [Property] {
        properties.filter { $0.status == "rental" }
    }
    
    var activeProperties: [Property] {
        properties.filter { $0.status != "for_sale" }
    }
    
    init() {
        setupRealtimeSubscription()
    }
    
    deinit {
        realtimeTask?.cancel()
    }
    
    func fetchProperties() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let fetchedProperties = try await databaseService.fetchAll()
                await MainActor.run {
                    self.properties = fetchedProperties
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
    
    func createProperty(_ property: Property) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let createdProperty = try await databaseService.create(property)
                await MainActor.run {
                    if !self.properties.contains(where: { $0.id == createdProperty.id }) {
                        self.properties.append(createdProperty)
                    }
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
    
    func updateProperty(_ property: Property) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let updatedProperty = try await databaseService.update(property)
                await MainActor.run {
                    if let index = self.properties.firstIndex(where: { $0.id == updatedProperty.id }) {
                        self.properties[index] = updatedProperty
                    }
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
    
    func deleteProperty(_ property: Property) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                try await databaseService.delete(id: property.id)
                await MainActor.run {
                    self.properties.removeAll { $0.id == property.id }
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
    
    func clearFilters() {
        selectedType = nil
        selectedStatus = nil
        searchText = ""
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealtimeSubscription() {
        realtimeTask = Task {
            do {
                try await realtimeManager.subscribeToAll(
                    table: "properties",
                    onInsert: { [weak self] (property: Property) in
                        guard let self = self else { return }
                        if !self.properties.contains(where: { $0.id == property.id }) {
                            self.properties.append(property)
                        }
                    },
                    onUpdate: { [weak self] (property: Property) in
                        guard let self = self else { return }
                        if let index = self.properties.firstIndex(where: { $0.id == property.id }) {
                            self.properties[index] = property
                        }
                    },
                    onDelete: { [weak self] (propertyId: String) in
                        guard let self = self else { return }
                        if let uuid = UUID(uuidString: propertyId) {
                            self.properties.removeAll { $0.id == uuid }
                        }
                    }
                )
            } catch {
                print("Failed to setup realtime subscription: \(error)")
            }
        }
    }
}
