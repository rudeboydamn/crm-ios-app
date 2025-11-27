import Foundation
import Combine

final class CommunicationViewModel: ObservableObject {
    @Published var communications: [Communication] = []
    @Published var contacts: [CommunicationContact] = []
    @Published var templates: [CommunicationTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedType: CommunicationType?
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var filteredCommunications: [Communication] {
        communications.filter { comm in
            let matchesSearch = searchText.isEmpty ||
                (comm.content ?? "").localizedCaseInsensitiveContains(searchText) ||
                (comm.subject?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesType = selectedType == nil || comm.type == selectedType
            
            return matchesSearch && matchesType
        }
        .sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
    
    var recentCommunications: [Communication] {
        Array(filteredCommunications.prefix(10))
    }
    
    init() {}
    
    func fetchCommunications() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchCommunications()
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
                receiveValue: { [weak self] fetchedCommunications in
                    guard let self = self else { return }
                    
                    self.communications = fetchedCommunications
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func createCommunication(_ communication: Communication) {
        isLoading = true
        errorMessage = nil
        
        networkService.createCommunication(communication)
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
                receiveValue: { [weak self] createdCommunication in
                    guard let self = self else { return }
                    
                    if !self.communications.contains(where: { $0.id == createdCommunication.id }) {
                        self.communications.insert(createdCommunication, at: 0)
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func updateCommunication(_ communication: Communication) {
        isLoading = true
        errorMessage = nil
        
        networkService.updateCommunication(communication)
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
                receiveValue: { [weak self] updatedCommunication in
                    guard let self = self else { return }
                    
                    if let index = self.communications.firstIndex(where: { $0.id == updatedCommunication.id }) {
                        self.communications[index] = updatedCommunication
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteCommunication(_ communication: Communication) {
        isLoading = true
        errorMessage = nil
        
        networkService.deleteCommunication(id: communication.id)
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
                    
                    self.communications.removeAll { $0.id == communication.id }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func clearFilters() {
        selectedType = nil
        searchText = ""
    }
    
    // MARK: - Contacts
    
    func fetchContacts() {
        // Fetch contacts from API
        // For now, initialize with empty array
    }
    
    func createContact(firstName: String, lastName: String, email: String?, phone: String?, company: String?, type: String) {
        let contact = CommunicationContact(
            id: UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            company: company,
            type: type,
            status: "active",
            source: nil,
            tags: nil,
            notes: nil,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        contacts.append(contact)
    }
    
    // MARK: - Templates
    
    func fetchTemplates() {
        // Fetch templates from API
    }
    
    func createTemplate(name: String, type: String, subject: String?, body: String) {
        let template = CommunicationTemplate(
            id: UUID().uuidString,
            name: name,
            type: type,
            subject: subject,
            body: body,
            category: nil,
            isActive: true,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        templates.append(template)
    }
    
    // MARK: - Send Methods
    
    func sendEmail(to: String, subject: String, body: String) {
        let comm = Communication(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            type: .email,
            direction: .outbound,
            subject: subject,
            content: body,
            notes: nil,
            duration: nil,
            status: "sent",
            date: Date(),
            contactName: nil,
            userId: nil,
            leadId: nil,
            clientId: nil,
            projectId: nil,
            propertyId: nil,
            contactId: nil,
            fromAddress: nil,
            toAddress: to,
            attachments: nil,
            tags: nil
        )
        communications.insert(comm, at: 0)
    }
    
    func sendSMS(to: String, message: String) {
        let comm = Communication(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            type: .sms,
            direction: .outbound,
            subject: nil,
            content: message,
            notes: nil,
            duration: nil,
            status: "sent",
            date: Date(),
            contactName: nil,
            userId: nil,
            leadId: nil,
            clientId: nil,
            projectId: nil,
            propertyId: nil,
            contactId: nil,
            fromAddress: nil,
            toAddress: to,
            attachments: nil,
            tags: nil
        )
        communications.insert(comm, at: 0)
    }
    
    func logCall(contactName: String, phone: String, duration: Int, outcome: String, notes: String) {
        let comm = Communication(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            type: .call,
            direction: .outbound,
            subject: nil,
            content: nil,
            notes: notes,
            duration: duration,
            status: outcome,
            date: Date(),
            contactName: contactName,
            userId: nil,
            leadId: nil,
            clientId: nil,
            projectId: nil,
            propertyId: nil,
            contactId: nil,
            fromAddress: nil,
            toAddress: phone,
            attachments: nil,
            tags: nil
        )
        communications.insert(comm, at: 0)
    }
}
