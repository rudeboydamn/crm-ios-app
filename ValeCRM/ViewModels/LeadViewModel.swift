import Foundation
import Combine
import Supabase

final class LeadViewModel: ObservableObject {
    @Published var leads: [Lead] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedSource: LeadSource?
    @Published var selectedStatus: LeadStatus?
    @Published var selectedPriority: LeadPriority?
    
    private let databaseService = LeadDatabaseService.shared
    private let realtimeManager = RealtimeManager.shared
    private let hubspotService = HubSpotService.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?
    
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
    
    init() {
        setupRealtimeSubscription()
    }
    
    deinit {
        realtimeTask?.cancel()
    }
    
    func fetchLeads() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let fetchedLeads = try await databaseService.fetchAll()
                await MainActor.run {
                    self.leads = fetchedLeads
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
    
    func createLead(_ lead: Lead) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let createdLead = try await databaseService.create(lead)
                
                // Optionally sync to HubSpot
                _ = try? await syncToHubSpot(createdLead)
                
                await MainActor.run {
                    // Real-time will handle the insert, but add optimistically
                    if !self.leads.contains(where: { $0.id == createdLead.id }) {
                        self.leads.insert(createdLead, at: 0)
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
    
    func updateLead(_ lead: Lead) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let updatedLead = try await databaseService.update(lead)
                
                // Optionally sync to HubSpot
                _ = try? await syncToHubSpot(updatedLead)
                
                await MainActor.run {
                    // Real-time will handle the update, but update optimistically
                    if let index = self.leads.firstIndex(where: { $0.id == updatedLead.id }) {
                        self.leads[index] = updatedLead
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
    
    func deleteLead(_ lead: Lead) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                try await databaseService.delete(id: lead.id)
                
                await MainActor.run {
                    // Real-time will handle the delete, but remove optimistically
                    self.leads.removeAll { $0.id == lead.id }
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
        selectedSource = nil
        selectedStatus = nil
        selectedPriority = nil
        searchText = ""
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealtimeSubscription() {
        realtimeTask = Task {
            do {
                try await realtimeManager.subscribeToAll(
                    table: "leads",
                    onInsert: { [weak self] (lead: Lead) in
                        guard let self = self else { return }
                        if !self.leads.contains(where: { $0.id == lead.id }) {
                            self.leads.insert(lead, at: 0)
                        }
                    },
                    onUpdate: { [weak self] (lead: Lead) in
                        guard let self = self else { return }
                        if let index = self.leads.firstIndex(where: { $0.id == lead.id }) {
                            self.leads[index] = lead
                        }
                    },
                    onDelete: { [weak self] (leadId: String) in
                        guard let self = self else { return }
                        if let uuid = UUID(uuidString: leadId) {
                            self.leads.removeAll { $0.id == uuid }
                        }
                    }
                )
            } catch {
                print("Failed to setup realtime subscription: \(error)")
            }
        }
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
    
    /// Search leads using database query
    func searchLeads(query: String) {
        guard !query.isEmpty else {
            fetchLeads()
            return
        }
        
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let results = try await databaseService.search(query: query)
                await MainActor.run {
                    self.leads = results
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
}
