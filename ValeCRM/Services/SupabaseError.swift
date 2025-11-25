import Foundation

/// Comprehensive error handling for Supabase operations
enum SupabaseError: Error, LocalizedError {
    // Authentication errors
    case authenticationFailed(String)
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case sessionExpired
    case tokenRefreshFailed
    
    // Database errors
    case databaseError(String)
    case recordNotFound
    case duplicateRecord
    case invalidQuery
    case constraintViolation
    
    // Network errors
    case networkError(String)
    case noInternetConnection
    case requestTimeout
    
    // Realtime errors
    case realtimeConnectionFailed
    case channelSubscriptionFailed
    case messageDecodingFailed
    
    // General errors
    case unknown(Error)
    case invalidConfiguration
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        // Authentication
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .sessionExpired:
            return "Your session has expired. Please sign in again"
        case .tokenRefreshFailed:
            return "Failed to refresh authentication token"
            
        // Database
        case .databaseError(let message):
            return "Database error: \(message)"
        case .recordNotFound:
            return "Record not found"
        case .duplicateRecord:
            return "A record with this information already exists"
        case .invalidQuery:
            return "Invalid database query"
        case .constraintViolation:
            return "Operation violates database constraints"
            
        // Network
        case .networkError(let message):
            return "Network error: \(message)"
        case .noInternetConnection:
            return "No internet connection available"
        case .requestTimeout:
            return "Request timed out"
            
        // Realtime
        case .realtimeConnectionFailed:
            return "Failed to establish real-time connection"
        case .channelSubscriptionFailed:
            return "Failed to subscribe to channel"
        case .messageDecodingFailed:
            return "Failed to decode real-time message"
            
        // General
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Invalid Supabase configuration"
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidCredentials:
            return "Please check your email and password and try again"
        case .sessionExpired:
            return "Please sign in again to continue"
        case .noInternetConnection:
            return "Please check your internet connection and try again"
        case .emailAlreadyExists:
            return "Try signing in or use a different email address"
        default:
            return nil
        }
    }
}

// MARK: - Error Mapping

extension SupabaseError {
    /// Map Supabase/Postgrest errors to SupabaseError
    static func map(_ error: Error) -> SupabaseError {
        let errorString = error.localizedDescription.lowercased()
        
        // Authentication errors
        if errorString.contains("invalid login credentials") ||
           errorString.contains("invalid email or password") {
            return .invalidCredentials
        }
        
        if errorString.contains("email not confirmed") {
            return .authenticationFailed("Email not confirmed")
        }
        
        if errorString.contains("user not found") {
            return .userNotFound
        }
        
        if errorString.contains("email already") ||
           errorString.contains("user already registered") {
            return .emailAlreadyExists
        }
        
        if errorString.contains("jwt expired") ||
           errorString.contains("token expired") {
            return .sessionExpired
        }
        
        // Network errors
        if errorString.contains("network") ||
           errorString.contains("connection") {
            return .networkError(error.localizedDescription)
        }
        
        if errorString.contains("timeout") {
            return .requestTimeout
        }
        
        // Database errors
        if errorString.contains("unique constraint") ||
           errorString.contains("duplicate key") {
            return .duplicateRecord
        }
        
        if errorString.contains("foreign key") ||
           errorString.contains("constraint") {
            return .constraintViolation
        }
        
        if errorString.contains("not found") {
            return .recordNotFound
        }
        
        // Default
        return .unknown(error)
    }
}
