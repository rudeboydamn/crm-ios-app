import Foundation
import Combine
import Supabase

final class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedStatus: TaskStatus?
    @Published var selectedPriority: TaskPriority?
    @Published var showOnlyOverdue = false
    @Published var showOnlyDueToday = false
    
    private let databaseService = TaskDatabaseService.shared
    private let realtimeManager = RealtimeManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTask: Task<Void, Never>?
    
    var filteredTasks: [Task] {
        tasks.filter { task in
            let matchesSearch = searchText.isEmpty ||
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesStatus = selectedStatus == nil || task.status == selectedStatus
            let matchesPriority = selectedPriority == nil || task.priority == selectedPriority
            let matchesOverdue = !showOnlyOverdue || task.isOverdue
            let matchesDueToday = !showOnlyDueToday || task.isDueToday
            
            return matchesSearch && matchesStatus && matchesPriority && matchesOverdue && matchesDueToday
        }
    }
    
    var pendingTasks: [Task] {
        tasks.filter { $0.status == .pending || $0.status == .inProgress }
    }
    
    var overdueTasks: [Task] {
        tasks.filter { $0.isOverdue }
    }
    
    var todayTasks: [Task] {
        tasks.filter { $0.isDueToday }
    }
    
    var completedTasks: [Task] {
        tasks.filter { $0.status == .completed }
    }
    
    init() {
        setupRealtimeSubscription()
    }
    
    deinit {
        realtimeTask?.cancel()
    }
    
    func fetchTasks() {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let fetchedTasks = try await databaseService.fetchAll()
                await MainActor.run {
                    self.tasks = fetchedTasks
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
    
    func createTask(_ task: Task) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let createdTask = try await databaseService.create(task)
                await MainActor.run {
                    if !self.tasks.contains(where: { $0.id == createdTask.id }) {
                        self.tasks.insert(createdTask, at: 0)
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
    
    func updateTask(_ task: Task) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                let updatedTask = try await databaseService.update(task)
                await MainActor.run {
                    if let index = self.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                        self.tasks[index] = updatedTask
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
    
    func deleteTask(_ task: Task) {
        Task {
            await MainActor.run { self.isLoading = true }
            
            do {
                try await databaseService.delete(id: task.id)
                await MainActor.run {
                    self.tasks.removeAll { $0.id == task.id }
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
    
    func markAsCompleted(_ task: Task) {
        var updatedTask = task
        updatedTask.status = .completed
        updatedTask.completedDate = Date()
        updateTask(updatedTask)
    }
    
    func clearFilters() {
        selectedStatus = nil
        selectedPriority = nil
        showOnlyOverdue = false
        showOnlyDueToday = false
        searchText = ""
    }
    
    // MARK: - Real-time Subscriptions
    
    private func setupRealtimeSubscription() {
        realtimeTask = Task {
            do {
                try await realtimeManager.subscribeToAll(
                    table: "tasks",
                    onInsert: { [weak self] (task: Task) in
                        guard let self = self else { return }
                        if !self.tasks.contains(where: { $0.id == task.id }) {
                            self.tasks.insert(task, at: 0)
                        }
                    },
                    onUpdate: { [weak self] (task: Task) in
                        guard let self = self else { return }
                        if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                            self.tasks[index] = task
                        }
                    },
                    onDelete: { [weak self] (taskId: String) in
                        guard let self = self else { return }
                        if let uuid = UUID(uuidString: taskId) {
                            self.tasks.removeAll { $0.id == uuid }
                        }
                    }
                )
            } catch {
                print("Failed to setup realtime subscription: \(error)")
            }
        }
    }
}
