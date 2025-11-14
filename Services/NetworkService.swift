import Foundation
import Combine

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(String)
    case serverError(Int, String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided."
        case .unauthorized:
            return "Authentication failed or token expired."
        case .noData:
            return "No data returned from server."
        case .decodingError:
            return "Failed to decode server response."
        case .networkError(let message):
            return message
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        }
    }
}

final class NetworkService: ObservableObject {
    static let shared = NetworkService()

    private var cancellables = Set<AnyCancellable>()

    private let supabaseURL: URL
    private let supabaseKey: String

    init() {
        guard let url = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL configuration")
        }
        self.supabaseURL = url
        self.supabaseKey = AppConfig.supabaseAnonKey
    }

    func request<T: Decodable>(from endpoint: String, method: String = "GET", body: Data? = nil) -> AnyPublisher<T, APIError> {
        let url = supabaseURL.appendingPathComponent("/rest/v1/\(endpoint)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError("Invalid response.")
                }
                guard 200..<300 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 401 {
                        throw APIError.unauthorized
                    }
                    throw APIError.serverError(httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                }
                guard !data.isEmpty else { throw APIError.noData }
                return data
            }
            .decode(type: T.self, decoder: configuredDecoder())
            .mapError { error in
                if let apiError = error as? APIError { return apiError }
                if error is DecodingError { return .decodingError }
                return .networkError(error.localizedDescription)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func configuredDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
    
    // MARK: - Typed API Methods
    
    func fetchLeads() -> AnyPublisher<[Lead], APIError> {
        request(from: "leads?select=*&order=created_at.desc")
    }
    
    func createLead(_ lead: Lead) -> AnyPublisher<Lead, APIError> {
        guard let body = try? JSONEncoder().encode(lead) else {
            return Fail(error: APIError.decodingError).eraseToAnyPublisher()
        }
        return request(from: "leads", method: "POST", body: body)
    }
    
    func updateLead(_ lead: Lead) -> AnyPublisher<Lead, APIError> {
        guard let body = try? JSONEncoder().encode(lead) else {
            return Fail(error: APIError.decodingError).eraseToAnyPublisher()
        }
        return request(from: "leads?id=eq.\(lead.id.uuidString)", method: "PATCH", body: body)
    }
    
    func deleteLead(id: UUID) -> AnyPublisher<Void, APIError> {
        request(from: "leads?id=eq.\(id.uuidString)", method: "DELETE")
    }
    
    func fetchProperties() -> AnyPublisher<[Property], APIError> {
        request(from: "properties?select=*&order=created_at.desc")
    }
    
    func createProperty(_ property: Property) -> AnyPublisher<Property, APIError> {
        guard let body = try? JSONEncoder().encode(property) else {
            return Fail(error: APIError.decodingError).eraseToAnyPublisher()
        }
        return request(from: "properties", method: "POST", body: body)
    }
    
    func updateProperty(_ property: Property) -> AnyPublisher<Property, APIError> {
        guard let body = try? JSONEncoder().encode(property) else {
            return Fail(error: APIError.decodingError).eraseToAnyPublisher()
        }
        return request(from: "properties?id=eq.\(property.id.uuidString)", method: "PATCH", body: body)
    }
    
    func fetchRehabProjects() -> AnyPublisher<[RehabProject], APIError> {
        request(from: "rehab_projects?select=*&order=start_date.desc")
    }
    
    func createRehabProject(_ project: RehabProject) -> AnyPublisher<RehabProject, APIError> {
        guard let body = try? JSONEncoder().encode(project) else {
            return Fail(error: APIError.decodingError).eraseToAnyPublisher()
        }
        return request(from: "rehab_projects", method: "POST", body: body)
    }
    
    func updateRehabProject(_ project: RehabProject) -> AnyPublisher<RehabProject, APIError> {
        guard let body = try? JSONEncoder().encode(project) else {
            return Fail(error: APIError.decodingError).eraseToAnyPublisher()
        }
        return request(from: "rehab_projects?id=eq.\(project.id.uuidString)", method: "PATCH", body: body)
    }
}
