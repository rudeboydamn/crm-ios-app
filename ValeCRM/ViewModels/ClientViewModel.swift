import Foundation
import Combine
import Supabase

final class ClientViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedType: ClientType?
    @Published var selectedStatus: ClientStatus?
    
    private let databaseService = ClientDatabaseService.shared
    private let realtimeManager = RealtimeManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?
    
    var filteredClients: [Client] {
        clients.filter { client in
            let matchesSearch = searchText.isEmpty ||
                client.fullName.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText) ||
                (client.company?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesType = selectedType == nil || client.type == selectedType
            let matchesStatus = selectedStatus == nil || client.status == selectedStatus
            
            return matchesSearch && matchesType && matchesStatus
        }
    }
    
    var activeClients: [Client] {
        clients.filter { $0.status == .active }
    }
    
    var recentClients: [Client] {
        Array(clients.prefix(5))
    }
    
    init() {
        setupRealtimeSubscription()
    }
    
    deinit {
        realtimeTask?.cancel()
    }
    
    func fetchClients() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let fetchedClients = try await databaseService.fetchAll()
                await MainActor.run {
                    self.clients = fetchedClients
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
    
    func createClient(_ client: Client) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let createdClient = try await databaseService.create(client)
                await MainActor.run {
                    if !self.clients.contains(where: { $0.id == createdClient.id }) {
                        self.clients.insert(createdClient, at: 0)
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
    
    func updateClient(_ client: Client) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let updatedClient = try await databaseService.update(client)
                await MainActor.run {
                    if let index = self.clients.firstIndex(where: { $0.id == updatedClient.id }) {
                        self.clients[index] = updatedClient
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
    
    func deleteClient(_ client: Client) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                try await databaseService.delete(id: client.id)
                await MainActor.run {
                    self.clients.removeAll { $0.id == client.id }
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
                    table: "clients",
                    onInsert: { [weak self] (client: Client) in
                        guard let self = self else { return }
                        if !self.clients.contains(where: { $0.id == client.id }) {
                            self.clients.insert(client, at: 0)
                        }
                    },
                    onUpdate: { [weak self] (client: Client) in
                        guard let self = self else { return }
                        if let index = self.clients.firstIndex(where: { $0.id == client.id }) {
                            self.clients[index] = client
                        }
                    },
                    onDelete: { [weak self] (clientId: String) in
                        guard let self = self else { return }
                        if let uuid = UUID(uuidString: clientId) {
                            self.clients.removeAll { $0.id == uuid }
                        }
                    }
                )
            } catch {
                print("Failed to setup realtime subscription: \(error)")
            }
        }
    }
}
