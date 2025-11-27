import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    @Published var metrics: ReportDashboardMetrics?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefresh: Date?
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {}
    
    func fetchMetrics() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchDashboardMetrics()
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    switch completion {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] value in
                    guard let self = self else { return }
                    
                    self.metrics = value
                    self.lastRefresh = Date()
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func refresh() {
        fetchMetrics()
    }
}
