import Foundation
import Supabase

/// Database service for Task operations
final class TaskDatabaseService: BaseDatabaseService<Task> {
    static let shared = TaskDatabaseService()
    
    private init() {
        super.init(tableName: "tasks")
    }
    
    /// Search tasks by title or description
    func search(query: String) async throws -> [Task] {
        do {
            let response: [Task] = try await supabase.database
                .from(tableName)
                .select()
                .or("title.ilike.%\(query)%,description.ilike.%\(query)%")
                .order("due_date", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter tasks by status
    func fetchByStatus(_ status: TaskStatus) async throws -> [Task] {
        do {
            let response: [Task] = try await supabase.database
                .from(tableName)
                .select()
                .eq("status", value: status.rawValue)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter tasks by priority
    func fetchByPriority(_ priority: TaskPriority) async throws -> [Task] {
        do {
            let response: [Task] = try await supabase.database
                .from(tableName)
                .select()
                .eq("priority", value: priority.rawValue)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch tasks by assigned user
    func fetchByAssignedUser(userId: String) async throws -> [Task] {
        do {
            let response: [Task] = try await supabase.database
                .from(tableName)
                .select()
                .eq("assigned_to", value: userId)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch overdue tasks
    func fetchOverdue() async throws -> [Task] {
        do {
            let formatter = ISO8601DateFormatter()
            let now = formatter.string(from: Date())
            
            let response: [Task] = try await supabase.database
                .from(tableName)
                .select()
                .lt("due_date", value: now)
                .neq("status", value: TaskStatus.completed.rawValue)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch upcoming tasks (next 7 days)
    func fetchUpcoming() async throws -> [Task] {
        do {
            let formatter = ISO8601DateFormatter()
            let now = Date()
            let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now)!
            
            let response: [Task] = try await supabase.database
                .from(tableName)
                .select()
                .gte("due_date", value: formatter.string(from: now))
                .lte("due_date", value: formatter.string(from: nextWeek))
                .neq("status", value: TaskStatus.completed.rawValue)
                .order("due_date", ascending: true)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
}
