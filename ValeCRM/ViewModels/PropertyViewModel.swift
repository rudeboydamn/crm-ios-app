import Foundation
import Combine

final class PropertyViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedType: String?
    @Published var selectedStatus: String?
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var filteredProperties: [Property] {
        properties.filter { property in
            let matchesSearch = searchText.isEmpty ||
                (property.address ?? "").localizedCaseInsensitiveContains(searchText) ||
                (property.city ?? "").localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedType == nil || property.propertyType == selectedType
            let matchesStatus = selectedStatus == nil || property.status == selectedStatus
            
            return matchesSearch && matchesType && matchesStatus
        }
    }
    
    var totalPortfolioValue: Double {
        properties.compactMap { $0.marketValue }.reduce(0, +)
    }
    
    var totalMonthlyIncome: Double {
        0  // Would need to aggregate from units
    }
    
    var totalMonthlyExpenses: Double {
        0  // Would need to aggregate from expenses
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
    
    init() {}
    
    func fetchProperties() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchProperties()
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] fetchedProperties in
                    guard let self = self else { return }
                    
                    self.properties = fetchedProperties
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func createProperty(_ property: Property) {
        isLoading = true
        errorMessage = nil
        
        networkService.createProperty(property)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] createdProperty in
                    guard let self = self else { return }
                    
                    if !self.properties.contains(where: { $0.id == createdProperty.id }) {
                        self.properties.append(createdProperty)
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func updateProperty(_ property: Property) {
        isLoading = true
        errorMessage = nil
        
        networkService.updateProperty(property)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] updatedProperty in
                    guard let self = self else { return }
                    
                    if let index = self.properties.firstIndex(where: { $0.id == updatedProperty.id }) {
                        self.properties[index] = updatedProperty
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteProperty(_ property: Property) {
        isLoading = true
        errorMessage = nil
        
        networkService.deleteProperty(id: property.id)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.properties.removeAll { $0.id == property.id }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func clearFilters() {
        selectedType = nil
        selectedStatus = nil
        searchText = ""
    }
}
