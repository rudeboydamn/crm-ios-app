import SwiftUI

struct EnhancedDashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var dashboardViewModel: DashboardViewModel
    @StateObject var leadViewModel: LeadViewModel
    @StateObject var taskViewModel: TaskViewModel
    @StateObject var projectViewModel: RehabProjectViewModel
    
    init() {
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel())
        _leadViewModel = StateObject(wrappedValue: LeadViewModel())
        _taskViewModel = StateObject(wrappedValue: TaskViewModel())
        _projectViewModel = StateObject(wrappedValue: RehabProjectViewModel())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HeaderSection()
                    
                    // Quick Stats
                    QuickStatsSection(metrics: dashboardViewModel.metrics)
                    
                    // Activity Overview
                    ActivityOverviewSection(
                        taskViewModel: taskViewModel,
                        leadViewModel: leadViewModel
                    )
                    
                    // Performance Charts
                    if let metrics = dashboardViewModel.metrics {
                        PerformanceSection(metrics: metrics)
                    }
                    
                    // Recent Items
                    RecentItemsSection(
                        leads: leadViewModel.recentLeads,
                        tasks: taskViewModel.todayTasks
                    )
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { refreshData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        dashboardViewModel.fetchMetrics()
        leadViewModel.fetchLeads()
        taskViewModel.fetchTasks()
        projectViewModel.fetchProjects()
    }
    
    private func refreshData() {
        loadData()
    }
}

struct HeaderSection: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let user = authManager.currentUser {
                Text("Welcome back, \(user.name)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Here's what's happening today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuickStatsSection: View {
    let metrics: ReportDashboardMetrics?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total Leads",
                    value: "\(metrics?.totalLeads ?? 0)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Projects",
                    value: "\(metrics?.activeProjects ?? 0)",
                    icon: "hammer.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Properties",
                    value: "\(metrics?.totalProperties ?? 0)",
                    icon: "building.2.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Pending Tasks",
                    value: "\(metrics?.pendingTasks ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: .purple
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ActivityOverviewSection: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var leadViewModel: LeadViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ActivityRow(
                    icon: "exclamationmark.circle.fill",
                    title: "Overdue Tasks",
                    count: taskViewModel.overdueTasks.count,
                    color: .red
                )
                
                ActivityRow(
                    icon: "clock.fill",
                    title: "Tasks Due Today",
                    count: taskViewModel.todayTasks.count,
                    color: .orange
                )
                
                ActivityRow(
                    icon: "flame.fill",
                    title: "Hot Leads",
                    count: leadViewModel.hotLeads.count,
                    color: .red
                )
                
                ActivityRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "New Leads This Week",
                    count: leadViewModel.recentLeads.count,
                    color: .blue
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

struct PerformanceSection: View {
    let metrics: ReportDashboardMetrics
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Performance")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                PerformanceBar(
                    title: "Lead Conversion Rate",
                    value: metrics.conversionRate ?? 0,
                    color: .green
                )
                
                PerformanceBar(
                    title: "Rent Collection Rate",
                    value: metrics.collectionRate ?? 0,
                    color: .blue
                )
                
                PerformanceBar(
                    title: "Occupancy Rate",
                    value: metrics.occupancyRate ?? 0,
                    color: .purple
                )
                
                let profitMargin = metrics.profitMargin ?? 0
                if profitMargin > 0 {
                    PerformanceBar(
                        title: "Profit Margin",
                        value: profitMargin,
                        color: .green
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct PerformanceBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text(String(format: "%.1f%%", value))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: min(geometry.size.width * CGFloat(value / 100), geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct RecentItemsSection: View {
    let leads: [Lead]
    let tasks: [Task]
    
    var body: some View {
        VStack(spacing: 16) {
            // Recent Leads
            if !leads.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Leads")
                        .font(.headline)
                    
                    ForEach(leads.prefix(3)) { lead in
                        LeadRowCompact(lead: lead)
                    }
                }
            }
            
            // Today's Tasks
            if !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Tasks")
                        .font(.headline)
                    
                    ForEach(tasks.prefix(3)) { task in
                        TaskRowCompact(task: task)
                    }
                }
            }
        }
    }
}

struct LeadRowCompact: View {
    let lead: Lead
    
    var body: some View {
        HStack {
            Circle()
                .fill(priorityColor(lead.priority ?? .warm))
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
            
            Text((lead.status?.rawValue ?? "new").capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func priorityColor(_ priority: LeadPriority) -> Color {
        switch priority {
        case .hot: return .red
        case .warm: return .orange
        case .cold: return .blue
        }
    }
}

struct TaskRowCompact: View {
    let task: Task
    
    var body: some View {
        HStack {
            Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.status == .completed ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .foregroundColor(task.isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
            if task.isOverdue {
                Text("Overdue")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}
