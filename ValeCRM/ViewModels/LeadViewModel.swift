import Foundation
import Combine

final class LeadViewModel: ObservableObject {
    @Published var leads: [Lead] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedSource: LeadSource?
    @Published var selectedStatus: LeadStatus?
    @Published var selectedPriority: LeadPriority?
    
    private let networkService = NetworkService.shared
    private let hubspotService = HubSpotService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var filteredLeads: [Lead] {
        leads.filter { lead in
            let matchesSearch = searchText.isEmpty ||
                lead.fullName.localizedCaseInsensitiveContains(searchText) ||
                (lead.email ?? "").localizedCaseInsensitiveContains(searchText) ||
                (lead.propertyAddress ?? "").localizedCaseInsensitiveContains(searchText)
            
            let matchesSource = selectedSource == nil || lead.source == selectedSource
            let matchesStatus = selectedStatus == nil || lead.status == selectedStatus
            let matchesPriority = selectedPriority == nil || lead.priority == selectedPriority
            
            return matchesSearch && matchesSource && matchesStatus && matchesPriority
        }
    }
    
    var hotLeads: [Lead] {
        leads.filter { $0.priority == .hot }
    }
    
    var recentLeads: [Lead] {
        Array(leads.prefix(5))
    }
    
    init() {}
    
    func fetchLeads() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchLeads()
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
                receiveValue: { [weak self] fetchedLeads in
                    guard let self = self else { return }
                    
                    self.leads = fetchedLeads
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func createLead(_ lead: Lead) {
        isLoading = true
        errorMessage = nil
        
        networkService.createLead(lead)
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
                receiveValue: { [weak self] createdLead in
                    guard let self = self else { return }
                    
                    if !self.leads.contains(where: { $0.id == createdLead.id }) {
                        self.leads.insert(createdLead, at: 0)
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                    
                    _Concurrency.Task {
                        await MainActor.run {
                            self.isLoading = true
                        }
                        _ = try? await self.syncToHubSpot(createdLead)
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func updateLead(_ lead: Lead) {
        isLoading = true
        errorMessage = nil
        
        networkService.updateLead(lead)
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
                receiveValue: { [weak self] updatedLead in
                    guard let self = self else { return }
                    
                    if let index = self.leads.firstIndex(where: { $0.id == updatedLead.id }) {
                        self.leads[index] = updatedLead
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                    
                    _Concurrency.Task {
                        await MainActor.run {
                            self.isLoading = true
                        }
                        _ = try? await self.syncToHubSpot(updatedLead)
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteLead(_ lead: Lead) {
        isLoading = true
        errorMessage = nil
        
        networkService.deleteLead(id: lead.id)
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
                    
                    self.leads.removeAll { $0.id == lead.id }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func clearFilters() {
        selectedSource = nil
        selectedStatus = nil
        selectedPriority = nil
        searchText = ""
    }
    
    // MARK: - Helper Methods
    
    private func syncToHubSpot(_ lead: Lead) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            hubspotService.syncLeadToHubSpot(lead)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { hubspotId in
                        continuation.resume(returning: hubspotId)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /// Search leads using local filtering over fetched leads
    func searchLeads(query: String) {
        searchText = query
        
        if query.isEmpty {
            fetchLeads()
        } else if leads.isEmpty {
            fetchLeads()
        }
    }
}
