import Foundation
import Combine
import LocalAuthentication

enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case biometricNotAvailable
    case biometricFailed
    case keychainError(String)
    case networkError(String)
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricFailed:
            return "Biometric authentication failed"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        }
    }
}

struct User: Codable {
    let id: String
    let email: String
    let fullName: String?
    let avatarUrl: String?
    let createdAt: Date
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkService: NetworkService
    private let keychainHelper = KeychainHelper.shared
    private var cancellables = Set<AnyCancellable>()
    
    private let accessTokenKey = "com.keystonevale.valeCRM.accessToken"
    private let refreshTokenKey = "com.keystonevale.valeCRM.refreshToken"
    private let userKey = "com.keystonevale.valeCRM.user"
    
    init(networkService: NetworkService) {
        self.networkService = networkService
        checkAuthStatus()
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Failed to encode login data"
            isLoading = false
            return
        }
        
        networkService.request(from: "auth/v1/token?grant_type=password", method: "POST", body: jsonData)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (response: AuthResponse) in
                self?.handleAuthSuccess(response)
            })
            .store(in: &cancellables)
    }
    
    func signUp(email: String, password: String, fullName: String) {
        isLoading = true
        errorMessage = nil
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Failed to encode signup data"
            isLoading = false
            return
        }
        
        networkService.request(from: "auth/v1/signup", method: "POST", body: jsonData)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] (response: AuthResponse) in
                self?.handleAuthSuccess(response)
            })
            .store(in: &cancellables)
    }
    
    func signOut() {
        do {
            try keychainHelper.delete(for: accessTokenKey)
            try keychainHelper.delete(for: refreshTokenKey)
            try keychainHelper.delete(for: userKey)
        } catch {
            print("Error clearing keychain: \(error)")
        }
        
        isAuthenticated = false
        currentUser = nil
    }
    
    func authenticateWithBiometrics(completion: @escaping (Result<Void, AuthError>) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(.failure(.biometricNotAvailable))
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to access ValeCRM"
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.checkAuthStatus()
                    completion(.success(()))
                } else {
                    completion(.failure(.biometricFailed))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handleAuthSuccess(_ response: AuthResponse) {
        do {
            try keychainHelper.save(response.accessToken, for: accessTokenKey)
            try keychainHelper.save(response.refreshToken, for: refreshTokenKey)
            
            let encoder = JSONEncoder()
            let userData = try encoder.encode(response.user)
            try keychainHelper.save(userData, for: userKey)
            
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = "Failed to save authentication data: \(error.localizedDescription)"
        }
    }
    
    private func checkAuthStatus() {
        do {
            let accessToken = try keychainHelper.readString(for: accessTokenKey)
            let userData = try keychainHelper.read(for: userKey)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let user = try decoder.decode(User.self, from: userData)
            
            if !accessToken.isEmpty {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func getAccessToken() -> String? {
        try? keychainHelper.readString(for: accessTokenKey)
    }
    
    func refreshAccessToken() {
        guard let refreshToken = try? keychainHelper.readString(for: refreshTokenKey) else {
            signOut()
            return
        }
        
        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return
        }
        
        networkService.request(from: "auth/v1/token?grant_type=refresh_token", method: "POST", body: jsonData)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.signOut()
                }
            }, receiveValue: { [weak self] (response: AuthResponse) in
                self?.handleAuthSuccess(response)
            })
            .store(in: &cancellables)
    }
}
