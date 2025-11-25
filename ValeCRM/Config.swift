import Foundation

struct AppConfig {
    // MARK: - Website API Configuration
    static let apiBaseURL: String = value(for: "APIBaseURL")
    static let apiURL = URL(string: apiBaseURL)!
    
    // MARK: - JWT Configuration
    static let jwtSecret: String = value(for: "JWTSecret")
    static let jwtExpiry = "24h"
    
    // MARK: - Admin Credentials (for testing)
    static let adminUserId: String = value(for: "AdminUserId")
    static let adminEmail: String = value(for: "AdminEmail")
    
    // MARK: - Email Configuration
    static let fromEmail: String = value(for: "FromEmail")
    static let adminEmailAddress: String = value(for: "AdminEmailAddress")
    
    // MARK: - HubSpot Configuration
    static let hubSpotAPIKey: String = value(for: "HubSpotAPIKey")
    static let hubSpotPortalID: String = value(for: "HubSpotPortalID")
    
    // MARK: - Supabase Configuration
    static let supabaseURL: String = value(for: "SupabaseURL")
    static let supabaseAnonKey: String = value(for: "SupabaseAnonKey")
    
    // MARK: - App Information
    static let appName: String = value(for: "AppName")
    static let appVersion: String = value(for: "AppVersion")
    static let companyName: String = value(for: "CompanyName")
    static let supportEmail: String = value(for: "SupportEmail")
    static let websiteURL: String = value(for: "WebsiteURL")
    static let phoneNumber: String = value(for: "PhoneNumber")
    
    // MARK: - Helpers
    private static func value(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            fatalError("Missing configuration value for key: \(key). Ensure ConfigSecrets.xcconfig defines it.")
        }
        return value
    }
}
