import Foundation
import Combine

final class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedStatus: TaskStatus?
    @Published var selectedPriority: TaskPriority?
    @Published var showOnlyOverdue = false
    @Published var showOnlyDueToday = false
    
    private let networkService = NetworkService.shared
    private var cancellables = Set<AnyCancellable>()
    
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
    
    init() {}
    
    func fetchTasks() {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchTasks()
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
                receiveValue: { [weak self] fetchedTasks in
                    guard let self = self else { return }
                    
                    self.tasks = fetchedTasks
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func createTask(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        networkService.createTask(task)
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
                receiveValue: { [weak self] createdTask in
                    guard let self = self else { return }
                    
                    if !self.tasks.contains(where: { $0.id == createdTask.id }) {
                        self.tasks.insert(createdTask, at: 0)
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func updateTask(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        networkService.updateTask(task)
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
                receiveValue: { [weak self] updatedTask in
                    guard let self = self else { return }
                    
                    if let index = self.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                        self.tasks[index] = updatedTask
                    }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteTask(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        networkService.deleteTask(id: task.id)
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
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.tasks.removeAll { $0.id == task.id }
                    self.isLoading = false
                    self.errorMessage = nil
                }
            )
            .store(in: &cancellables)
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
}
