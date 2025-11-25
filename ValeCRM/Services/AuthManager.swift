import Foundation
import Combine
import LocalAuthentication
import Supabase

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
    let userId: String  // This is the username
    let email: String
    let name: String
    let role: String
    let isActive: Bool?
    let createdAt: Date?
    let lastLogin: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "userId"
        case email
        case name
        case role
        case isActive = "isActive"
        case createdAt = "createdAt"
        case lastLogin = "lastLogin"
    }
}

struct AuthResponse: Codable {
    let user: User
    let token: String  // JWT token
    
    enum CodingKeys: String, CodingKey {
        case user
        case token
    }
}

final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared
    private var authStateTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
        checkInitialAuthStatus()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await MainActor.run {
                self.isAuthenticated = true
                self.isLoading = false
            }
            
            // Fetch user profile from database
            await fetchUserProfile(userId: session.user.id.uuidString)
            
        } catch {
            await MainActor.run {
                self.errorMessage = SupabaseError.map(error).localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Sign up new user
    func signUp(email: String, password: String, name: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create auth user
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            guard let user = authResponse.user else {
                throw SupabaseError.authenticationFailed("No user returned")
            }
            
            // Create user profile in database
            let userProfile = User(
                id: user.id.uuidString,
                userId: userId,
                email: email,
                name: name,
                role: "user",
                isActive: true,
                createdAt: Date(),
                lastLogin: Date()
            )
            
            try await supabase.database
                .from("users")
                .insert(userProfile)
                .execute()
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isAuthenticated = true
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = SupabaseError.map(error).localizedDescription
                self.isLoading = false
            }
        }
    }
    
    
    /// Sign out current user
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = SupabaseError.map(error).localizedDescription
            }
        }
    }
    
    /// Authenticate with biometrics (Face ID / Touch ID)
    func authenticateWithBiometrics() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to access ValeCRM"
            ) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AuthError.biometricFailed)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Setup listener for auth state changes
    private func setupAuthStateListener() {
        authStateTask = Task {
            for await state in await supabase.auth.authStateChanges {
                await handleAuthStateChange(state.event, session: state.session)
            }
        }
    }
    
    /// Handle auth state changes
    private func handleAuthStateChange(_ event: AuthChangeEvent, session: Session?) async {
        await MainActor.run {
            switch event {
            case .signedIn:
                self.isAuthenticated = true
            case .signedOut:
                self.isAuthenticated = false
                self.currentUser = nil
            case .tokenRefreshed:
                // Token refreshed, session is still valid
                break
            case .userUpdated:
                // User metadata updated
                break
            default:
                break
            }
        }
        
        // Fetch user profile when signed in
        if event == .signedIn, let userId = session?.user.id.uuidString {
            await fetchUserProfile(userId: userId)
        }
    }
    
    /// Check initial auth status on app launch
    private func checkInitialAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                
                await MainActor.run {
                    self.isAuthenticated = session.accessToken.isEmpty == false
                }
                
                if isAuthenticated {
                    await fetchUserProfile(userId: session.user.id.uuidString)
                }
            } catch {
                await MainActor.run {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    /// Fetch user profile from database
    private func fetchUserProfile(userId: String) async {
        do {
            let response: [User] = try await supabase.database
                .from("users")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            
            await MainActor.run {
                self.currentUser = response.first
            }
        } catch {
            print("Failed to fetch user profile: \(error)")
        }
    }
    
    /// Get current session
    func getCurrentSession() async throws -> Session {
        return try await supabase.auth.session
    }
    
    /// Reset password
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = SupabaseError.map(error).localizedDescription
                self.isLoading = false
            }
        }
    }
}
