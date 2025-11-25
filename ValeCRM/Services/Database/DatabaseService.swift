import Foundation
import Supabase

/// Base protocol for database operations with common CRUD methods
protocol DatabaseServiceProtocol {
    associatedtype Entity: Codable & Identifiable where Entity.ID == UUID
    
    var tableName: String { get }
    var supabase: SupabaseManager { get }
    
    func fetchAll() async throws -> [Entity]
    func fetch(id: UUID) async throws -> Entity?
    func create(_ entity: Entity) async throws -> Entity
    func update(_ entity: Entity) async throws -> Entity
    func delete(id: UUID) async throws
    func search(query: String) async throws -> [Entity]
}

/// Base database service with common CRUD implementations
class BaseDatabaseService<T: Codable & Identifiable> where T.ID == UUID {
    let tableName: String
    let supabase: SupabaseManager
    
    init(tableName: String, supabase: SupabaseManager = .shared) {
        self.tableName = tableName
        self.supabase = supabase
    }
    
    /// Fetch all records
    func fetchAll() async throws -> [T] {
        do {
            let response: [T] = try await supabase.database
                .from(tableName)
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch record by ID
    func fetch(id: UUID) async throws -> T? {
        do {
            let response: [T] = try await supabase.database
                .from(tableName)
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value
            
            return response.first
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Create new record
    func create(_ entity: T) async throws -> T {
        do {
            let response: [T] = try await supabase.database
                .from(tableName)
                .insert(entity)
                .select()
                .execute()
                .value
            
            guard let created = response.first else {
                throw SupabaseError.databaseError("Failed to create record")
            }
            
            return created
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Update existing record
    func update(_ entity: T) async throws -> T {
        do {
            let response: [T] = try await supabase.database
                .from(tableName)
                .update(entity)
                .eq("id", value: entity.id.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw SupabaseError.databaseError("Failed to update record")
            }
            
            return updated
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Delete record by ID
    func delete(id: UUID) async throws {
        do {
            try await supabase.database
                .from(tableName)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch with pagination
    func fetchPaginated(limit: Int = 20, offset: Int = 0) async throws -> [T] {
        do {
            let response: [T] = try await supabase.database
                .from(tableName)
                .select()
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Count total records
    func count() async throws -> Int {
        do {
            let response = try await supabase.database
                .from(tableName)
                .select("*", head: true, count: .exact)
                .execute()
            
            return response.count ?? 0
        } catch {
            throw SupabaseError.map(error)
        }
    }
}
