import Foundation

struct AppConfig {
    // MARK: - Supabase Configuration
    static let supabaseURL = "https://wjdbivxcrloqyblmqqui.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqZGJpdnhjcmxvcXlibG1xcXVpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMDM1MTIsImV4cCI6MjA3Nzg3OTUxMn0.l6GFoJOHDn0IaGRQdqbPNAXwkaH74LkGLXoYeIX0dqk"
    static let supabaseServiceKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndqZGJpdnhjcmxvcXlibG1xcXVpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjMwMzUxMiwiZXhwIjoyMDc3ODc5NTEyfQ.rnE6jYDwKuHqIOhtCLiMVbwM3YjXXPVoXUU83SJuNkE"
    
    // MARK: - HubSpot Configuration
    static let hubspotAppName = "KeystoneCRM"
    static let hubspotAppId = "23785997"
    static let hubspotClientId = "5777ca1e-b90b-4475-9c1e-147d07ac9605"
    static let hubspotClientSecret = "fcf9afb2-229b-4f87-99ea-f57a612ace36"
    
    // MARK: - Email Configuration (Zoho)
    static let zohoEmail = "dammy@dammyhenry.com"
    static let zohoPassword = "B5AcXzs6dXTv"
    
    // MARK: - Domain
    static let domain = "keystonevale.org"
    
    // MARK: - App Information
    static let appName = "ValeCRM"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
}
