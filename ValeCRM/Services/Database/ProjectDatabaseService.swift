import Foundation
import Supabase

/// Database service for RehabProject operations
final class ProjectDatabaseService: BaseDatabaseService<RehabProject> {
    static let shared = ProjectDatabaseService()
    
    private init() {
        super.init(tableName: "projects")
    }
    
    /// Search projects by name or property address
    func search(query: String) async throws -> [RehabProject] {
        do {
            let response: [RehabProject] = try await supabase.database
                .from(tableName)
                .select()
                .or("project_name.ilike.%\(query)%,property_address.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter projects by status
    func fetchByStatus(_ status: ProjectStatus) async throws -> [RehabProject] {
        do {
            let response: [RehabProject] = try await supabase.database
                .from(tableName)
                .select()
                .eq("status", value: status.rawValue)
                .order("start_date", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch active projects
    func fetchActive() async throws -> [RehabProject] {
        do {
            let response: [RehabProject] = try await supabase.database
                .from(tableName)
                .select()
                .in("status", values: [ProjectStatus.planning.rawValue, ProjectStatus.inProgress.rawValue])
                .order("start_date", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter projects by property ID
    func fetchByProperty(propertyId: String) async throws -> [RehabProject] {
        do {
            let response: [RehabProject] = try await supabase.database
                .from(tableName)
                .select()
                .eq("property_id", value: propertyId)
                .order("start_date", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Calculate total budget across all projects
    func calculateTotalBudget() async throws -> Double {
        do {
            let projects = try await fetchAll()
            return projects.reduce(0) { $0 + $1.totalBudget }
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Calculate total spent across all projects
    func calculateTotalSpent() async throws -> Double {
        do {
            let projects = try await fetchAll()
            return projects.reduce(0) { $0 + $1.actualCost }
        } catch {
            throw SupabaseError.map(error)
        }
    }
}
