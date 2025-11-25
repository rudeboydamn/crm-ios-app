import Foundation
import Combine
import Supabase

final class CommunicationViewModel: ObservableObject {
    @Published var communications: [Communication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedType: CommunicationType?
    
    private let databaseService = CommunicationDatabaseService.shared
    private let realtimeManager = RealtimeManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?
    
    var filteredCommunications: [Communication] {
        communications.filter { comm in
            let matchesSearch = searchText.isEmpty ||
                comm.content.localizedCaseInsensitiveContains(searchText) ||
                (comm.subject?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesType = selectedType == nil || comm.type == selectedType
            
            return matchesSearch && matchesType
        }
        .sorted { $0.createdAt > $1.createdAt }
    }
    
    var recentCommunications: [Communication] {
        Array(filteredCommunications.prefix(10))
    }
    
    init() {
        setupRealtimeSubscription()
    }
    
    deinit {
        realtimeTask?.cancel()
    }
    
    func fetchCommunications() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let fetchedCommunications = try await databaseService.fetchAll()
                await MainActor.run {
                    self.communications = fetchedCommunications
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
    
    func createCommunication(_ communication: Communication) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let createdCommunication = try await databaseService.create(communication)
                await MainActor.run {
                    if !self.communications.contains(where: { $0.id == createdCommunication.id }) {
                        self.communications.insert(createdCommunication, at: 0)
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
    
    func updateCommunication(_ communication: Communication) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let updatedCommunication = try await databaseService.update(communication)
                await MainActor.run {
                    if let index = self.communications.firstIndex(where: { $0.id == updatedCommunication.id }) {
                        self.communications[index] = updatedCommunication
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
    
    func deleteCommunication(_ communication: Communication) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                try await databaseService.delete(id: communication.id)
                await MainActor.run {
                    self.communications.removeAll { $0.id == communication.id }
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
        searchText = ""
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealtimeSubscription() {
        realtimeTask = Task {
            do {
                try await realtimeManager.subscribeToAll(
                    table: "communications",
                    onInsert: { [weak self] (communication: Communication) in
                        guard let self = self else { return }
                        if !self.communications.contains(where: { $0.id == communication.id }) {
                            self.communications.insert(communication, at: 0)
                        }
                    },
                    onUpdate: { [weak self] (communication: Communication) in
                        guard let self = self else { return }
                        if let index = self.communications.firstIndex(where: { $0.id == communication.id }) {
                            self.communications[index] = communication
                        }
                    },
                    onDelete: { [weak self] (commId: String) in
                        guard let self = self else { return }
                        if let uuid = UUID(uuidString: commId) {
                            self.communications.removeAll { $0.id == uuid }
                        }
                    }
                )
            } catch {
                print("Failed to setup realtime subscription: \(error)")
            }
        }
    }
}
