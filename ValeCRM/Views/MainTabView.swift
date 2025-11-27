import SwiftUI

// MARK: - Main Tab View (Root Navigation)
struct MainTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var portfolioVM = PortfolioViewModel()
    @StateObject private var projectVM = RehabProjectViewModel()
    @StateObject private var leadsVM = LeadViewModel()
    @StateObject private var commsVM = CommunicationViewModel()
    @StateObject private var taskVM = TaskViewModel()
    
    var body: some View {
        TabView {
            // Dashboard - Landing Page
            DashboardHomeView()
                .environmentObject(dashboardVM)
                .environmentObject(portfolioVM)
                .environmentObject(projectVM)
                .environmentObject(leadsVM)
                .environmentObject(taskVM)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Portfolio Manager
            PortfolioManagerView()
                .environmentObject(portfolioVM)
                .tabItem {
                    Label("Portfolio", systemImage: "building.2.fill")
                }
            
            // Rehab Projects
            ProjectsManagerView()
                .environmentObject(projectVM)
                .tabItem {
                    Label("Projects", systemImage: "hammer.fill")
                }
            
            // Communications
            CommunicationsHubView()
                .environmentObject(commsVM)
                .tabItem {
                    Label("Comms", systemImage: "message.fill")
                }
            
            // Leads & CRM
            LeadsManagerView()
                .environmentObject(leadsVM)
                .environmentObject(taskVM)
                .tabItem {
                    Label("Leads", systemImage: "person.2.fill")
                }
        }
        .accentColor(.blue)
        .onAppear {
            loadInitialData()
        }
    }
    
    private func loadInitialData() {
        dashboardVM.fetchDashboardMetrics()
        portfolioVM.fetchPortfolioData()
        projectVM.fetchProjects()
        leadsVM.fetchLeads()
        taskVM.fetchTasks()
    }
}

// MARK: - Dashboard Home View (Landing Page)
struct DashboardHomeView: View {
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var projectVM: RehabProjectViewModel
    @EnvironmentObject var leadsVM: LeadViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        OverviewCard(
                            title: "Portfolio Value",
                            value: formatCurrency(dashboardVM.metrics?.totalPortfolioValue ?? 0),
                            icon: "building.2.fill",
                            color: .blue,
                            subtitle: "\(dashboardVM.metrics?.totalProperties ?? 0) Properties"
                        )
                        
                        OverviewCard(
                            title: "Active Projects",
                            value: "\(dashboardVM.metrics?.activeProjects ?? 0)",
                            icon: "hammer.fill",
                            color: .orange,
                            subtitle: "of \(dashboardVM.metrics?.totalProjects ?? 0) total"
                        )
                        
                        OverviewCard(
                            title: "Total Leads",
                            value: "\(dashboardVM.metrics?.totalLeads ?? 0)",
                            icon: "person.2.fill",
                            color: .green,
                            subtitle: "\(dashboardVM.metrics?.newLeads ?? 0) new"
                        )
                        
                        OverviewCard(
                            title: "Pending Tasks",
                            value: "\(dashboardVM.metrics?.pendingTasks ?? 0)",
                            icon: "checkmark.circle.fill",
                            color: .purple,
                            subtitle: "\(dashboardVM.metrics?.completedTasks ?? 0) completed"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Portfolio Summary
                    DashboardSection(title: "Portfolio Overview", icon: "building.2") {
                        PortfolioSummaryCard(viewModel: portfolioVM)
                    }
                    
                    // Active Projects
                    DashboardSection(title: "Active Projects", icon: "hammer") {
                        ActiveProjectsCard(projects: Array(projectVM.projects.prefix(3)))
                    }
                    
                    // Recent Leads
                    DashboardSection(title: "Recent Leads", icon: "person.badge.plus") {
                        RecentLeadsCard(leads: Array(leadsVM.leads.prefix(5)))
                    }
                    
                    // Upcoming Tasks
                    DashboardSection(title: "Upcoming Tasks", icon: "calendar") {
                        UpcomingTasksCard(tasks: taskVM.pendingTasks.prefix(5).map { $0 })
                    }
                    
                    // Communications Summary
                    DashboardSection(title: "Communications", icon: "envelope") {
                        CommsSummaryCard()
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshAll) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .refreshable {
                refreshAll()
            }
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.bold)
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func refreshAll() {
        dashboardVM.fetchDashboardMetrics()
        portfolioVM.fetchPortfolioData()
        projectVM.fetchProjects()
        leadsVM.fetchLeads()
        taskVM.fetchTasks()
    }
}

// MARK: - Overview Card
struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Dashboard Section
struct DashboardSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            content
        }
    }
}

// MARK: - Portfolio Summary Card
struct PortfolioSummaryCard: View {
    @ObservedObject var viewModel: PortfolioViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatItem(label: "Properties", value: "\(viewModel.properties.count)", color: .blue)
                StatItem(label: "Units", value: "\(viewModel.totalUnits)", color: .green)
                StatItem(label: "Occupancy", value: "\(Int(viewModel.occupancyRate))%", color: .orange)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Monthly Revenue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(viewModel.totalMonthlyRent))
                        .font(.headline)
                        .foregroundColor(.green)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Collection Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(viewModel.collectionRate))%")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Projects Card
struct ActiveProjectsCard: View {
    let projects: [RehabProject]
    
    var body: some View {
        VStack(spacing: 8) {
            if projects.isEmpty {
                EmptyStateSmall(message: "No active projects")
            } else {
                ForEach(projects) { project in
                    ProjectRowSmall(project: project)
                    if project.id != projects.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ProjectRowSmall: View {
    let project: RehabProject
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.propertyName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(project.propertyAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(project.budgetUtilization))%")
                    .font(.caption)
                    .fontWeight(.medium)
                ProgressView(value: project.budgetUtilization / 100)
                    .frame(width: 60)
            }
        }
    }
}

// MARK: - Recent Leads Card
struct RecentLeadsCard: View {
    let leads: [Lead]
    
    var body: some View {
        VStack(spacing: 8) {
            if leads.isEmpty {
                EmptyStateSmall(message: "No leads yet")
            } else {
                ForEach(leads) { lead in
                    LeadRowSmall(lead: lead)
                    if lead.id != leads.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct LeadRowSmall: View {
    let lead: Lead
    
    var body: some View {
        HStack {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(lead.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(lead.propertyAddress ?? "No address")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: lead.status?.rawValue ?? "new")
        }
    }
    
    private var priorityColor: Color {
        switch lead.priority {
        case .hot: return .red
        case .warm: return .orange
        case .cold: return .blue
        case .none: return .gray
        }
    }
}

// MARK: - Upcoming Tasks Card
struct UpcomingTasksCard: View {
    let tasks: [Task]
    
    var body: some View {
        VStack(spacing: 8) {
            if tasks.isEmpty {
                EmptyStateSmall(message: "No pending tasks")
            } else {
                ForEach(tasks) { task in
                    TaskRowSmall(task: task)
                    if task.id != tasks.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TaskRowSmall: View {
    let task: Task
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let dueDate = task.dueDate {
                    Text(formatDate(dueDate))
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
            PriorityBadge(priority: task.priority)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Comms Summary Card
struct CommsSummaryCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                CommStatItem(icon: "envelope.fill", label: "Emails", value: "0", color: .blue)
                CommStatItem(icon: "message.fill", label: "SMS", value: "0", color: .green)
                CommStatItem(icon: "phone.fill", label: "Calls", value: "0", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CommStatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "new": return .blue
        case "contacted": return .orange
        case "qualified": return .green
        case "negotiating": return .purple
        case "closed", "won": return .green
        case "lost": return .red
        default: return .gray
        }
    }
}

// MARK: - Priority Badge
struct PriorityBadge: View {
    let priority: TaskPriority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Empty State Small
struct EmptyStateSmall: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager(networkService: NetworkService.shared))
}
