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
    
    private let networkService: NetworkService
    private let hubspotService: HubSpotService
    private var cancellables = Set<AnyCancellable>()
    
    var filteredLeads: [Lead] {
        leads.filter { lead in
            let matchesSearch = searchText.isEmpty ||
                lead.fullName.localizedCaseInsensitiveContains(searchText) ||
                lead.email.localizedCaseInsensitiveContains(searchText) ||
                lead.propertyAddress.localizedCaseInsensitiveContains(searchText)
            
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
    
    init(networkService: NetworkService, hubspotService: HubSpotService = .shared) {
        self.networkService = networkService
        self.hubspotService = hubspotService
    }
    
    func fetchLeads() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchLeads()
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] leads in
                self?.leads = leads
            })
            .store(in: &cancellables)
    }
    
    func createLead(_ lead: Lead) {
        isLoading = true
        errorMessage = nil
        
        networkService.createLead(lead)
            .flatMap { [weak self] createdLead -> AnyPublisher<Lead, APIError> in
                guard let self = self else {
                    return Fail(error: APIError.networkError("ViewModel deallocated")).eraseToAnyPublisher()
                }
                
                return self.hubspotService.syncLeadToHubSpot(createdLead)
                    .map { hubspotId in
                        var updatedLead = createdLead
                        updatedLead.hubspotId = hubspotId
                        return updatedLead
                    }
                    .catch { _ in Just(createdLead).setFailureType(to: APIError.self) }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] lead in
                self?.leads.insert(lead, at: 0)
            })
            .store(in: &cancellables)
    }
    
    func updateLead(_ lead: Lead) {
        isLoading = true
        errorMessage = nil
        
        networkService.updateLead(lead)
            .flatMap { [weak self] updatedLead -> AnyPublisher<Lead, APIError> in
                guard let self = self else {
                    return Fail(error: APIError.networkError("ViewModel deallocated")).eraseToAnyPublisher()
                }
                
                return self.hubspotService.syncLeadToHubSpot(updatedLead)
                    .map { hubspotId in
                        var finalLead = updatedLead
                        finalLead.hubspotId = hubspotId
                        return finalLead
                    }
                    .catch { _ in Just(updatedLead).setFailureType(to: APIError.self) }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] updatedLead in
                if let index = self?.leads.firstIndex(where: { $0.id == updatedLead.id }) {
                    self?.leads[index] = updatedLead
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteLead(_ lead: Lead) {
        isLoading = true
        errorMessage = nil
        
        networkService.deleteLead(id: lead.id)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] _ in
                self?.leads.removeAll { $0.id == lead.id }
            })
            .store(in: &cancellables)
    }
    
    func clearFilters() {
        selectedSource = nil
        selectedStatus = nil
        selectedPriority = nil
        searchText = ""
    }
}
