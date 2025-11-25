import Foundation
import Combine
import Supabase

final class DashboardViewModel: ObservableObject {
    @Published var metrics: ReportDashboardMetrics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefresh: Date?
    
    private let supabase = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    func fetchMetrics() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                // Fetch dashboard metrics from database
                // This may require a custom RPC function in Supabase
                let response: ReportDashboardMetrics = try await supabase.database
                    .rpc("get_dashboard_metrics")
                    .execute()
                    .value
                
                await MainActor.run {
                    self.metrics = response
                    self.lastRefresh = Date()
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = SupabaseError.map(error).localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func refresh() {
        fetchMetrics()
    }
}
