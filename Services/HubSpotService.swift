import Foundation
import Combine

struct HubSpotContact: Codable {
    let id: String?
    let properties: [String: String]
    
    init(id: String? = nil, properties: [String: String]) {
        self.id = id
        self.properties = properties
    }
}

struct HubSpotDeal: Codable {
    let id: String?
    let properties: [String: String]
    
    init(id: String? = nil, properties: [String: String]) {
        self.id = id
        self.properties = properties
    }
}

final class HubSpotService: ObservableObject {
    static let shared = HubSpotService()
    
    private let baseURL = "https://api.hubapi.com"
    private var cancellables = Set<AnyCancellable>()
    
    private var accessToken: String?
    
    private init() {}
    
    // MARK: - Authentication
    
    func setAccessToken(_ token: String) {
        self.accessToken = token
    }
    
    // MARK: - Contacts
    
    func createContact(from lead: Lead) -> AnyPublisher<HubSpotContact, Error> {
        let properties: [String: String] = [
            "firstname": lead.firstName,
            "lastname": lead.lastName,
            "email": lead.email,
            "phone": lead.phone,
            "address": lead.propertyAddress,
            "city": lead.propertyCity,
            "state": lead.propertyState,
            "zip": lead.propertyZip,
            "lifecyclestage": mapLeadStatusToLifecycle(lead.status),
            "hs_lead_status": lead.status.rawValue
        ]
        
        let contact = HubSpotContact(properties: properties)
        
        guard let jsonData = try? JSONEncoder().encode(contact) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return request(endpoint: "/crm/v3/objects/contacts", method: "POST", body: jsonData)
    }
    
    func updateContact(hubspotId: String, from lead: Lead) -> AnyPublisher<HubSpotContact, Error> {
        let properties: [String: String] = [
            "firstname": lead.firstName,
            "lastname": lead.lastName,
            "email": lead.email,
            "phone": lead.phone,
            "address": lead.propertyAddress,
            "city": lead.propertyCity,
            "state": lead.propertyState,
            "zip": lead.propertyZip,
            "lifecyclestage": mapLeadStatusToLifecycle(lead.status),
            "hs_lead_status": lead.status.rawValue
        ]
        
        let contact = HubSpotContact(id: hubspotId, properties: properties)
        
        guard let jsonData = try? JSONEncoder().encode(contact) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return request(endpoint: "/crm/v3/objects/contacts/\(hubspotId)", method: "PATCH", body: jsonData)
    }
    
    func syncLeadToHubSpot(_ lead: Lead) -> AnyPublisher<String, Error> {
        if let hubspotId = lead.hubspotId {
            return updateContact(hubspotId: hubspotId, from: lead)
                .map { _ in hubspotId }
                .eraseToAnyPublisher()
        } else {
            return createContact(from: lead)
                .compactMap { $0.id }
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Deals
    
    func createDeal(from lead: Lead, contactId: String) -> AnyPublisher<HubSpotDeal, Error> {
        var properties: [String: String] = [
            "dealname": "\(lead.propertyAddress) - \(lead.fullName)",
            "dealstage": mapLeadStatusToDealStage(lead.status),
            "pipeline": "default"
        ]
        
        if let amount = lead.offerAmount {
            properties["amount"] = String(amount)
        }
        
        let deal = HubSpotDeal(properties: properties)
        
        guard let jsonData = try? JSONEncoder().encode(deal) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return request(endpoint: "/crm/v3/objects/deals", method: "POST", body: jsonData)
    }
    
    // MARK: - Private Methods
    
    private func request<T: Decodable>(endpoint: String, method: String, body: Data? = nil) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func mapLeadStatusToLifecycle(_ status: LeadStatus) -> String {
        switch status {
        case .new:
            return "lead"
        case .contacted, .qualified:
            return "marketingqualifiedlead"
        case .appointmentScheduled:
            return "salesqualifiedlead"
        case .offerMade, .contract:
            return "opportunity"
        case .closed:
            return "customer"
        case .lost:
            return "other"
        }
    }
    
    private func mapLeadStatusToDealStage(_ status: LeadStatus) -> String {
        switch status {
        case .new, .contacted:
            return "appointmentscheduled"
        case .qualified:
            return "qualifiedtobuy"
        case .appointmentScheduled:
            return "presentationscheduled"
        case .offerMade:
            return "decisionmakerboughtin"
        case .contract:
            return "contractsent"
        case .closed:
            return "closedwon"
        case .lost:
            return "closedlost"
        }
    }
}
