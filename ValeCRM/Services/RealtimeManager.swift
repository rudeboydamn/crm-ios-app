import Foundation
import Supabase
import Combine

/// Real-time event types
enum RealtimeEvent {
    case insert
    case update
    case delete
}

/// Real-time change notification
struct RealtimeChange<T: Codable> {
    let event: RealtimeEvent
    let record: T?
    let oldRecord: T?
}

/// Manager for Supabase real-time subscriptions
final class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()
    
    private let supabase = SupabaseManager.shared
    private var channels: [String: RealtimeChannel] = [:]
    private var subscriptions: Set<AnyCancellable> = []
    
    @Published var connectionStatus: RealtimeConnectionStatus = .disconnected
    @Published var isConnected: Bool = false
    
    private init() {
        setupConnectionListener()
    }
    
    // MARK: - Connection Management
    
    /// Setup connection status listener
    private func setupConnectionListener() {
        // Monitor realtime connection status
        Task {
            // Connect to realtime
            await supabase.realtime.connect()
            
            await MainActor.run {
                self.isConnected = true
                self.connectionStatus = .connected
            }
        }
    }
    
    /// Disconnect from realtime
    func disconnect() async {
        for (_, channel) in channels {
            await supabase.realtime.removeChannel(channel)
        }
        channels.removeAll()
        
        await MainActor.run {
            self.isConnected = false
            self.connectionStatus = .disconnected
        }
    }
    
    // MARK: - Channel Subscriptions
    
    /// Subscribe to table changes
    func subscribe<T: Codable>(
        to table: String,
        event: RealtimeEvent? = nil,
        filter: String? = nil,
        onChange: @escaping (RealtimeChange<T>) -> Void
    ) async throws {
        let channelName = generateChannelName(table: table, filter: filter)
        
        // Remove existing channel if present
        if let existingChannel = channels[channelName] {
            await supabase.realtime.removeChannel(existingChannel)
        }
        
        // Create new channel
        let channel = await supabase.realtime.channel(channelName)
        
        // Subscribe to table changes
        let changeStream = await channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: table,
            filter: filter
        )
        
        // Listen for changes
        Task {
            for await change in changeStream {
                await handleChange(change, onChange: onChange)
            }
        }
        
        // Subscribe to channel
        await channel.subscribe()
        
        channels[channelName] = channel
    }
    
    /// Subscribe to all events on a table
    func subscribeToAll<T: Codable>(
        table: String,
        onInsert: ((T) -> Void)? = nil,
        onUpdate: ((T) -> Void)? = nil,
        onDelete: ((String) -> Void)? = nil
    ) async throws {
        let channelName = "all_\(table)_changes"
        
        // Remove existing channel if present
        if let existingChannel = channels[channelName] {
            await supabase.realtime.removeChannel(existingChannel)
        }
        
        // Create new channel
        let channel = await supabase.realtime.channel(channelName)
        
        // Subscribe to inserts
        if let onInsert = onInsert {
            let insertStream = await channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: table
            )
            
            Task {
                for await insert in insertStream {
                    if let record = try? insert.decodeRecord(as: T.self) {
                        await MainActor.run {
                            onInsert(record)
                        }
                    }
                }
            }
        }
        
        // Subscribe to updates
        if let onUpdate = onUpdate {
            let updateStream = await channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: table
            )
            
            Task {
                for await update in updateStream {
                    if let record = try? update.decodeRecord(as: T.self) {
                        await MainActor.run {
                            onUpdate(record)
                        }
                    }
                }
            }
        }
        
        // Subscribe to deletes
        if let onDelete = onDelete {
            let deleteStream = await channel.postgresChange(
                DeleteAction.self,
                schema: "public",
                table: table
            )
            
            Task {
                for await delete in deleteStream {
                    if let oldRecord = try? delete.decodeOldRecord(as: T.self),
                       let id = (oldRecord as? any Identifiable)?.id as? String {
                        await MainActor.run {
                            onDelete(id)
                        }
                    }
                }
            }
        }
        
        // Subscribe to channel
        await channel.subscribe()
        
        channels[channelName] = channel
    }
    
    /// Unsubscribe from table
    func unsubscribe(from table: String, filter: String? = nil) async {
        let channelName = generateChannelName(table: table, filter: filter)
        
        if let channel = channels[channelName] {
            await supabase.realtime.removeChannel(channel)
            channels.removeValue(forKey: channelName)
        }
    }
    
    /// Unsubscribe from all channels
    func unsubscribeAll() async {
        for (_, channel) in channels {
            await supabase.realtime.removeChannel(channel)
        }
        channels.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func generateChannelName(table: String, filter: String?) -> String {
        if let filter = filter {
            return "\(table)_\(filter)"
        }
        return table
    }
    
    private func handleChange<T: Codable>(
        _ change: Any,
        onChange: @escaping (RealtimeChange<T>) -> Void
    ) async {
        // Parse change event and call onChange handler
        // This is a simplified version - actual implementation depends on Supabase SDK
        if let insertChange = change as? InsertAction {
            if let record = try? insertChange.decodeRecord(as: T.self) {
                await MainActor.run {
                    onChange(RealtimeChange(event: .insert, record: record, oldRecord: nil))
                }
            }
        } else if let updateChange = change as? UpdateAction {
            if let record = try? updateChange.decodeRecord(as: T.self),
               let oldRecord = try? updateChange.decodeOldRecord(as: T.self) {
                await MainActor.run {
                    onChange(RealtimeChange(event: .update, record: record, oldRecord: oldRecord))
                }
            }
        } else if let deleteChange = change as? DeleteAction {
            if let oldRecord = try? deleteChange.decodeOldRecord(as: T.self) {
                await MainActor.run {
                    onChange(RealtimeChange(event: .delete, record: nil, oldRecord: oldRecord))
                }
            }
        }
    }
}

// MARK: - Connection Status

enum RealtimeConnectionStatus {
    case connected
    case connecting
    case disconnected
    case error(String)
    
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
