import Foundation
import Supabase

/// Database service for Document operations
final class DocumentDatabaseService: BaseDatabaseService<Document> {
    static let shared = DocumentDatabaseService()
    
    private init() {
        super.init(tableName: "documents")
    }
    
    /// Search documents by name or description
    func search(query: String) async throws -> [Document] {
        do {
            let response: [Document] = try await supabase.database
                .from(tableName)
                .select()
                .or("document_name.ilike.%\(query)%,description.ilike.%\(query)%")
                .order("uploaded_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Filter documents by type
    func fetchByType(_ type: DocumentType) async throws -> [Document] {
        do {
            let response: [Document] = try await supabase.database
                .from(tableName)
                .select()
                .eq("document_type", value: type.rawValue)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Fetch documents by related entity
    func fetchByEntity(entityType: String, entityId: String) async throws -> [Document] {
        do {
            let response: [Document] = try await supabase.database
                .from(tableName)
                .select()
                .eq("related_entity_type", value: entityType)
                .eq("related_entity_id", value: entityId)
                .order("uploaded_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Upload document to Supabase Storage
    func uploadDocument(data: Data, fileName: String, mimeType: String) async throws -> String {
        do {
            let path = "documents/\(UUID().uuidString)_\(fileName)"
            
            try await supabase.storage
                .from("documents")
                .upload(
                    path: path,
                    file: data,
                    options: FileOptions(
                        contentType: mimeType,
                        upsert: false
                    )
                )
            
            // Get public URL
            let publicURL = try supabase.storage
                .from("documents")
                .getPublicURL(path: path)
            
            return publicURL.absoluteString
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Download document from Supabase Storage
    func downloadDocument(path: String) async throws -> Data {
        do {
            let data = try await supabase.storage
                .from("documents")
                .download(path: path)
            
            return data
        } catch {
            throw SupabaseError.map(error)
        }
    }
    
    /// Delete document from Supabase Storage
    func deleteDocumentFromStorage(path: String) async throws {
        do {
            try await supabase.storage
                .from("documents")
                .remove(paths: [path])
        } catch {
            throw SupabaseError.map(error)
        }
    }
}
