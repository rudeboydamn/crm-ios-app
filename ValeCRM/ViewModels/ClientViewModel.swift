import Foundation
import Combine

final class ClientViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedType: ClientType?
    @Published var selectedStatus: ClientStatus?
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
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
    
    init() {}
    
    func fetchClients() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchClients()
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
                receiveValue: { [weak self] fetchedClients in
                    guard let self = self else { return }
                    
                    self.clients = fetchedClients
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func createClient(_ client: Client) {
        isLoading = true
        errorMessage = nil
        
        networkService.createClient(client)
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
                receiveValue: { [weak self] createdClient in
                    guard let self = self else { return }
                    
                    if !self.clients.contains(where: { $0.id == createdClient.id }) {
                        self.clients.insert(createdClient, at: 0)
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func updateClient(_ client: Client) {
        isLoading = true
        errorMessage = nil
        
        networkService.updateClient(client)
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
                receiveValue: { [weak self] updatedClient in
                    guard let self = self else { return }
                    
                    if let index = self.clients.firstIndex(where: { $0.id == updatedClient.id }) {
                        self.clients[index] = updatedClient
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteClient(_ client: Client) {
        isLoading = true
        errorMessage = nil
        
        networkService.deleteClient(id: client.id)
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
                    
                    self.clients.removeAll { $0.id == client.id }
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
