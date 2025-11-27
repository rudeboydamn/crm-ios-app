import Foundation
import Supabase

/// Centralized Supabase configuration and client management
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    // Supabase client instance
    let client: SupabaseClient
    
    private init() {
        // Safely read Supabase configuration; fail with clear errors if missing
        let supabaseURLString = AppConfig.supabaseURL
        guard !supabaseURLString.isEmpty,
              let supabaseURL = URL(string: supabaseURLString) else {
            fatalError("Supabase URL is missing or invalid. Ensure AppConfig.supabaseURL is set correctly in your configuration.")
        }
        
        let supabaseKey = AppConfig.supabaseAnonKey
        guard !supabaseKey.isEmpty else {
            fatalError("Supabase anon key is missing. Ensure AppConfig.supabaseAnonKey is set correctly in your configuration.")
        }
        
        print("[SupabaseManager] Initializing with URL: \(supabaseURL)")
        print("[SupabaseManager] SupabaseKey present: \(!supabaseKey.isEmpty)")
        print("[SupabaseManager] AppConfig.appVersion: '\(AppConfig.appVersion)'")
        
        print("[SupabaseManager] Creating SupabaseClient with auth options (emitLocalSessionAsInitialSession = true)...")
        
        let clientOptions = SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: clientOptions
        )
        
        print("[SupabaseManager] SupabaseClient initialized successfully.")
    }
    
    // MARK: - Convenience Accessors
    
    var auth: AuthClient {
        client.auth
    }
    
    var storage: SupabaseStorageClient {
        client.storage
    }
    
    /// Convenience helper for building Postgrest queries without accessing deprecated APIs
    func from(_ table: String) -> PostgrestQueryBuilder {
        client.from(table)
    }
    
    /// Access to Realtime v2 client
    var realtimeClient: RealtimeClientV2 {
        client.realtimeV2
    }
    
    // MARK: - Session Management
    
    /// Get current user session
    func getCurrentSession() async throws -> Session? {
        return try await auth.session
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        get async {
            do {
                let session = try await auth.session
                return session.accessToken.isEmpty == false
            } catch {
                return false
            }
        }
    }
    
    // NOTE: If you need the raw Supabase auth user, access `auth.session.user` directly.
}
