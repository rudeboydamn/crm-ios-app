import Foundation
import Supabase

/// Database service for Lead operations
final class LeadDatabaseService: BaseDatabaseService<Lead> {
    static let shared = LeadDatabaseService()
    
    private init() {
        super.init(tableName: "leads")
    }
    
    /// Search leads by name, email, or address
    func search(query: String) async throws -> [Lead] {
        do {
            let response: [Lead] = try await supabase.database
                .from(tableName)
                .select()
                .or("first_name.ilike.%\(query)%,last_name.ilike.%\(query)%,email.ilike.%\(query)%,property_address.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter leads by status
    func fetchByStatus(_ status: LeadStatus) async throws -> [Lead] {
        do {
            let response: [Lead] = try await supabase.database
                .from(tableName)
                .select()
                .eq("status", value: status.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter leads by priority
    func fetchByPriority(_ priority: LeadPriority) async throws -> [Lead] {
        do {
            let response: [Lead] = try await supabase.database
                .from(tableName)
                .select()
                .eq("priority", value: priority.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter leads by source
    func fetchBySource(_ source: LeadSource) async throws -> [Lead] {
        do {
            let response: [Lead] = try await supabase.database
                .from(tableName)
                .select()
                .eq("source", value: source.rawValue)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter leads by date range
    func fetchByDateRange(from startDate: Date, to endDate: Date) async throws -> [Lead] {
        do {
            let formatter = ISO8601DateFormatter()
            
            let response: [Lead] = try await supabase.database
                .from(tableName)
                .select()
                .gte("created_at", value: formatter.string(from: startDate))
                .lte("created_at", value: formatter.string(from: endDate))
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch leads with HubSpot ID
    func fetchWithHubSpotId() async throws -> [Lead] {
        do {
            let response: [Lead] = try await supabase.database
                .from(tableName)
                .select()
                .not("hubspot_id", operator: .is, value: "null")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
}
