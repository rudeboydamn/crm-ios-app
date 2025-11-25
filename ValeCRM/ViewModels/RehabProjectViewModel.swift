import Foundation
import Combine
import Supabase

final class RehabProjectViewModel: ObservableObject {
    @Published var projects: [RehabProject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: String?
    
    private let databaseService = ProjectDatabaseService.shared
    private let realtimeManager = RealtimeManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?
    
    var filteredProjects: [RehabProject] {
        guard let status = selectedStatus else { return projects }
        return projects.filter { $0.status == status }
    }
    
    var activeProjects: [RehabProject] {
        projects.filter { $0.status == "active" || $0.status == "Active" }
    }
    
    var totalBudget: Double {
        projects.reduce(0) { $0 + $1.totalBudget }
    }
    
    var totalSpent: Double {
        projects.reduce(0) { $0 + $1.totalSpent }
    }
    
    var totalRemaining: Double {
        projects.reduce(0) { $0 + $1.remainingBudget }
    }
    
    var totalInvestment: Double {
        projects.compactMap { $0.totalInvestment }.reduce(0, +)
    }
    
    var totalNetIncome: Double {
        projects.compactMap { $0.netIncome }.reduce(0, +)
    }
    
    var averageBudgetUtilization: Double {
        let utilizations = projects.map { $0.budgetUtilization }.filter { $0 > 0 }
        guard !utilizations.isEmpty else { return 0 }
        return utilizations.reduce(0, +) / Double(utilizations.count)
    }
    
    var averageROI: Double {
        let rois = projects.compactMap { $0.roi }.filter { $0 > 0 }
        guard !rois.isEmpty else { return 0 }
        return rois.reduce(0, +) / Double(rois.count)
    }
    
    init() {
        setupRealtimeSubscription()
    }
    
    deinit {
        realtimeTask?.cancel()
    }
    
    func fetchProjects() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let fetchedProjects = try await databaseService.fetchAll()
                await MainActor.run {
                    self.projects = fetchedProjects
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
    
    func createProject(_ project: RehabProject) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let createdProject = try await databaseService.create(project)
                await MainActor.run {
                    if !self.projects.contains(where: { $0.id == createdProject.id }) {
                        self.projects.append(createdProject)
                    }
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
    
    func updateProject(_ project: RehabProject) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let updatedProject = try await databaseService.update(project)
                await MainActor.run {
                    if let index = self.projects.firstIndex(where: { $0.id == updatedProject.id }) {
                        self.projects[index] = updatedProject
                    }
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
    
    func deleteProject(_ project: RehabProject) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                try await databaseService.delete(id: project.id)
                await MainActor.run {
                    self.projects.removeAll { $0.id == project.id }
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
    
    func clearFilter() {
        selectedStatus = nil
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealtimeSubscription() {
        realtimeTask = Task {
            do {
                try await realtimeManager.subscribeToAll(
                    table: "projects",
                    onInsert: { [weak self] (project: RehabProject) in
                        guard let self = self else { return }
                        if !self.projects.contains(where: { $0.id == project.id }) {
                            self.projects.append(project)
                        }
                    },
                    onUpdate: { [weak self] (project: RehabProject) in
                        guard let self = self else { return }
                        if let index = self.projects.firstIndex(where: { $0.id == project.id }) {
                            self.projects[index] = project
                        }
                    },
                    onDelete: { [weak self] (projectId: String) in
                        guard let self = self else { return }
                        if let uuid = UUID(uuidString: projectId) {
                            self.projects.removeAll { $0.id == uuid }
                        }
                    }
                )
            } catch {
                print("Failed to setup realtime subscription: \(error)")
            }
        }
    }
}
