import Foundation
import Combine

final class RehabProjectViewModel: ObservableObject {
    @Published var projects: [RehabProject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: ProjectStatus?
    
    private let networkService: NetworkService
    private var cancellables = Set<AnyCancellable>()
    
    var filteredProjects: [RehabProject] {
        guard let status = selectedStatus else { return projects }
        return projects.filter { $0.status == status }
    }
    
    var activeProjects: [RehabProject] {
        projects.filter { $0.status == .active }
    }
    
    var totalBudget: Double {
        projects.reduce(0) { $0 + $1.totalBudget }
    }
    
    var totalSpent: Double {
        projects.reduce(0) { $0 + $1.spentAmount }
    }
    
    var totalRemaining: Double {
        projects.reduce(0) { $0 + $1.remainingBudget }
    }
    
    var averageBudgetUtilization: Double {
        let utilizations = projects.map { $0.budgetUtilization }.filter { $0 > 0 }
        guard !utilizations.isEmpty else { return 0 }
        return utilizations.reduce(0, +) / Double(utilizations.count)
    }
    
    init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    func fetchProjects() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchRehabProjects()
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] projects in
                self?.projects = projects
            })
            .store(in: &cancellables)
    }
    
    func createProject(_ project: RehabProject) {
        isLoading = true
        errorMessage = nil
        
        networkService.createRehabProject(project)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] project in
                self?.projects.insert(project, at: 0)
            })
            .store(in: &cancellables)
    }
    
    func updateProject(_ project: RehabProject) {
        isLoading = true
        errorMessage = nil
        
        networkService.updateRehabProject(project)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] updatedProject in
                if let index = self?.projects.firstIndex(where: { $0.id == updatedProject.id }) {
                    self?.projects[index] = updatedProject
                }
            })
            .store(in: &cancellables)
    }
    
    func clearFilter() {
        selectedStatus = nil
    }
}
