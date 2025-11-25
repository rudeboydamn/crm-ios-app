import Foundation
import Supabase

/// Centralized Supabase configuration and client management
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    // Supabase client instance
    let client: SupabaseClient
    
    private init() {
        // Initialize Supabase client with configuration from Info.plist
        let supabaseURL = URL(string: AppConfig.supabaseURL)!
        let supabaseKey = AppConfig.supabaseAnonKey
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    schema: "public"
                ),
                auth: SupabaseClientOptions.AuthOptions(
                    autoRefreshToken: true,
                    persistSession: true,
                    detectSessionInUrl: false
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    headers: [
                        "X-Client-Info": "supabase-swift/\(AppConfig.appVersion)"
                    ]
                )
            )
        )
    }
    
    // MARK: - Convenience Accessors
    
    var auth: AuthClient {
        client.auth
    }
    
    var database: PostgrestClient {
        client.database
    }
    
    var realtime: RealtimeClient {
        client.realtime
    }
    
    var storage: StorageClient {
        client.storage
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
    
    /// Get current user
    func getCurrentUser() async throws -> User? {
        let session = try await auth.session
        return session.user
    }
}
