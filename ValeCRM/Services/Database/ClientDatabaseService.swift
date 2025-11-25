import Foundation
import Supabase

/// Database service for Client operations
final class ClientDatabaseService: BaseDatabaseService<Client> {
    static let shared = ClientDatabaseService()
    
    private init() {
        super.init(tableName: "clients")
    }
    
    /// Search clients by name, email, or company
    func search(query: String) async throws -> [Client] {
        do {
            let response: [Client] = try await supabase.database
                .from(tableName)
                .select()
                .or("first_name.ilike.%\(query)%,last_name.ilike.%\(query)%,email.ilike.%\(query)%,company_name.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter clients by type
    func fetchByType(_ type: ClientType) async throws -> [Client] {
        do {
            let response: [Client] = try await supabase.database
                .from(tableName)
                .select()
                .eq("client_type", value: type.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch active clients
    func fetchActive() async throws -> [Client] {
        do {
            let response: [Client] = try await supabase.database
                .from(tableName)
                .select()
                .eq("status", value: ClientStatus.active.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
}
