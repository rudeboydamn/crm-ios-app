import SwiftUI

// MARK: - Projects Manager Main View
struct ProjectsManagerView: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    @State private var selectedTab: ProjectTab = .dashboard
    
    enum ProjectTab: String, CaseIterable {
        case dashboard = "Dashboard"
        case allProjects = "All Projects"
        case pastProjects = "Past Projects"
        case reports = "Reports"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .allProjects: return "folder.fill"
            case .pastProjects: return "clock.arrow.circlepath"
            case .reports: return "doc.text.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .dashboard:
                        ProjectsDashboardView()
                    case .allProjects:
                        AllProjectsListView()
                    case .pastProjects:
                        PastProjectsListView()
                    case .reports:
                        ProjectReportsView()
                    case .settings:
                        ProjectSettingsView()
                    }
                }
                .environmentObject(viewModel)
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(ProjectTab.allCases, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Label(tab.rawValue, systemImage: tab.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.fetchProjects() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if viewModel.projects.isEmpty {
                viewModel.fetchProjects()
            }
        }
    }
}

// MARK: - Projects Dashboard View
struct ProjectsDashboardView: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    
    var activeProjects: [RehabProject] {
        viewModel.projects.filter { $0.status != .completed }
    }
    
    var completedProjects: [RehabProject] {
        viewModel.projects.filter { $0.status == .completed }
    }
    
    var totalBudget: Double {
        viewModel.projects.reduce(0) { $0 + $1.totalBudget }
    }
    
    var totalSpent: Double {
        viewModel.projects.reduce(0) { $0 + $1.totalSpent }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(
                        title: "Active Projects",
                        value: "\(activeProjects.count)",
                        icon: "hammer.fill",
                        color: .orange
                    )
                    MetricCard(
                        title: "Completed",
                        value: "\(completedProjects.count)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    MetricCard(
                        title: "Total Budget",
                        value: formatCurrency(totalBudget),
                        icon: "dollarsign.circle.fill",
                        color: .blue
                    )
                    MetricCard(
                        title: "Total Spent",
                        value: formatCurrency(totalSpent),
                        icon: "creditcard.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // Budget Overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Budget Overview")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Overall Budget Utilization")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(budgetUtilization))%")
                                .font(.headline)
                                .foregroundColor(budgetUtilization > 90 ? .red : .blue)
                        }
                        
                        ProgressView(value: min(budgetUtilization / 100, 1.0))
                            .tint(budgetUtilization > 90 ? .red : .blue)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(totalBudget - totalSpent))
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Average ROI")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(averageROI))%")
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
                
                // Active Projects Summary
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Active Projects")
                            .font(.headline)
                        Spacer()
                        Text("\(activeProjects.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if activeProjects.isEmpty {
                        EmptyStateView(
                            icon: "hammer",
                            title: "No Active Projects",
                            message: "Start a new rehab project"
                        )
                        .frame(height: 150)
                    } else {
                        ForEach(activeProjects.prefix(5)) { project in
                            ProjectSummaryRow(project: project)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            viewModel.fetchProjects()
        }
    }
    
    private var budgetUtilization: Double {
        guard totalBudget > 0 else { return 0 }
        return (totalSpent / totalBudget) * 100
    }
    
    private var averageROI: Double {
        let rois = viewModel.projects.map { $0.projectedROI }
        guard !rois.isEmpty else { return 0 }
        return rois.reduce(0, +) / Double(rois.count)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Project Summary Row
struct ProjectSummaryRow: View {
    let project: RehabProject
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.propertyName)
                        .font(.headline)
                    Text(project.propertyAddress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ProjectStatusBadge(status: project.status)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(project.totalBudget))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(project.totalSpent))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(project.budgetUtilization))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            ProgressView(value: min(project.budgetUtilization / 100, 1.0))
                .tint(project.budgetUtilization > 90 ? .red : .blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Project Status Badge
struct ProjectStatusBadge: View {
    let status: ProjectStatus
    
    var body: some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .planning: return .blue
        case .inProgress: return .orange
        case .onHold: return .yellow
        case .completed: return .green
        }
    }
}

// MARK: - All Projects List View
struct AllProjectsListView: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    @State private var showingAddProject = false
    @State private var searchText = ""
    @State private var filterStatus: ProjectStatus?
    
    var filteredProjects: [RehabProject] {
        var projects = viewModel.projects.filter { $0.status != .completed }
        
        if !searchText.isEmpty {
            projects = projects.filter {
                $0.propertyName.localizedCaseInsensitiveContains(searchText) ||
                $0.propertyAddress.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let status = filterStatus {
            projects = projects.filter { $0.status == status }
        }
        
        return projects
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter
            VStack(spacing: 8) {
                SearchBar(text: $searchText, placeholder: "Search projects...")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: filterStatus == nil) {
                            filterStatus = nil
                        }
                        ForEach([ProjectStatus.planning, .inProgress, .onHold], id: \.self) { status in
                            FilterChip(title: status.rawValue.capitalized, isSelected: filterStatus == status) {
                                filterStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredProjects.isEmpty {
                EmptyStateView(
                    icon: "hammer",
                    title: "No Projects",
                    message: "Tap + to create your first project"
                )
            } else {
                List {
                    ForEach(filteredProjects) { project in
                        NavigationLink(destination: ProjectDetailViewFull(project: project)) {
                            ProjectRowFull(project: project)
                        }
                    }
                    .onDelete(perform: deleteProjects)
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddProject = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectSheet()
                .environmentObject(viewModel)
        }
    }
    
    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = filteredProjects[index]
            viewModel.deleteProject(id: project.id)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Project Row Full
struct ProjectRowFull: View {
    let project: RehabProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.propertyName)
                    .font(.headline)
                Spacer()
                ProjectStatusBadge(status: project.status)
            }
            
            Text(project.propertyAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(formatCurrency(project.totalBudget), systemImage: "dollarsign.circle")
                    .font(.caption)
                
                Spacer()
                
                Text("\(Int(project.budgetUtilization))% used")
                    .font(.caption)
                    .foregroundColor(project.budgetUtilization > 90 ? .red : .secondary)
            }
            
            ProgressView(value: min(project.budgetUtilization / 100, 1.0))
                .tint(project.budgetUtilization > 90 ? .red : .blue)
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Past Projects List View
struct PastProjectsListView: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    
    var completedProjects: [RehabProject] {
        viewModel.projects.filter { $0.status == .completed }
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if completedProjects.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Completed Projects",
                    message: "Completed projects will appear here"
                )
            } else {
                List {
                    ForEach(completedProjects) { project in
                        NavigationLink(destination: ProjectDetailViewFull(project: project)) {
                            ProjectRowFull(project: project)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Project Reports View
struct ProjectReportsView: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ReportCard(
                        title: "Total Investment",
                        value: formatCurrency(totalInvestment),
                        trend: "+12%",
                        isPositive: true
                    )
                    ReportCard(
                        title: "Total Returns",
                        value: formatCurrency(totalReturns),
                        trend: "+8%",
                        isPositive: true
                    )
                    ReportCard(
                        title: "Avg Project Duration",
                        value: "\(avgDuration) days",
                        trend: "-5%",
                        isPositive: true
                    )
                    ReportCard(
                        title: "Success Rate",
                        value: "\(Int(successRate))%",
                        trend: "+2%",
                        isPositive: true
                    )
                }
                .padding(.horizontal)
                
                // Project Performance List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Project Performance")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.projects.prefix(10)) { project in
                        ProjectPerformanceRow(project: project)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var totalInvestment: Double {
        viewModel.projects.reduce(0) { $0 + $1.totalSpent }
    }
    
    private var totalReturns: Double {
        viewModel.projects.filter { $0.status == .completed }
            .reduce(0) { $0 + ($1.afterRepairValue - $1.totalSpent - $1.purchasePrice) }
    }
    
    private var avgDuration: Int {
        90 // Placeholder
    }
    
    private var successRate: Double {
        let completed = viewModel.projects.filter { $0.status == .completed }.count
        guard !viewModel.projects.isEmpty else { return 0 }
        return (Double(completed) / Double(viewModel.projects.count)) * 100
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Report Card
struct ReportCard: View {
    let title: String
    let value: String
    let trend: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                Text(trend)
            }
            .font(.caption)
            .foregroundColor(isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Project Performance Row
struct ProjectPerformanceRow: View {
    let project: RehabProject
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.propertyName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("ROI: \(Int(project.projectedROI))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(project.projectedProfit))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(project.projectedProfit > 0 ? .green : .red)
                ProjectStatusBadge(status: project.status)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Project Settings View
struct ProjectSettingsView: View {
    @State private var defaultBudgetBuffer = 10.0
    @State private var autoCalculateROI = true
    @State private var showCompletedInList = false
    
    var body: some View {
        Form {
            Section("Budget Settings") {
                HStack {
                    Text("Default Budget Buffer")
                    Spacer()
                    Text("\(Int(defaultBudgetBuffer))%")
                        .foregroundColor(.secondary)
                }
                Slider(value: $defaultBudgetBuffer, in: 0...30, step: 5)
            }
            
            Section("Display Settings") {
                Toggle("Auto-calculate ROI", isOn: $autoCalculateROI)
                Toggle("Show Completed in List", isOn: $showCompletedInList)
            }
            
            Section("Data") {
                Button("Export Projects") {
                    // Export logic
                }
                Button("Import Projects") {
                    // Import logic
                }
            }
        }
    }
}

// MARK: - Project Detail View Full
struct ProjectDetailViewFull: View {
    let project: RehabProject
    @State private var showingEdit = false
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text(project.propertyName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(project.propertyAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProjectStatusBadge(status: project.status)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Quick Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    QuickStat(label: "Budget", value: formatCurrency(project.totalBudget), color: .blue)
                    QuickStat(label: "Spent", value: formatCurrency(project.totalSpent), color: .orange)
                    QuickStat(label: "ROI", value: "\(Int(project.projectedROI))%", color: .green)
                }
                .padding(.horizontal)
                
                // Budget Progress
                VStack(alignment: .leading, spacing: 12) {
                    Text("Budget Progress")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Used")
                            Spacer()
                            Text("\(Int(project.budgetUtilization))%")
                        }
                        .font(.subheadline)
                        
                        ProgressView(value: min(project.budgetUtilization / 100, 1.0))
                            .tint(project.budgetUtilization > 90 ? .red : .blue)
                        
                        HStack {
                            Text("Remaining: \(formatCurrency(project.remainingBudget))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Financial Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Financial Details")
                        .font(.headline)
                    
                    DetailRowView(label: "Purchase Price", value: formatCurrency(project.purchasePrice))
                    DetailRowView(label: "Rehab Budget", value: formatCurrency(project.totalBudget))
                    DetailRowView(label: "After Repair Value", value: formatCurrency(project.afterRepairValue))
                    Divider()
                    DetailRowView(label: "Projected Profit", value: formatCurrency(project.projectedProfit))
                    DetailRowView(label: "Projected ROI", value: "\(Int(project.projectedROI))%")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Timeline
                VStack(alignment: .leading, spacing: 12) {
                    Text("Timeline")
                        .font(.headline)
                    
                    if let purchaseDate = project.purchaseDate {
                        TimelineRow(label: "Purchase Date", date: purchaseDate)
                    }
                    if let startDate = project.startDate {
                        TimelineRow(label: "Start Date", date: startDate)
                    }
                    if let endDate = project.endDate {
                        TimelineRow(label: "Target Completion", date: endDate)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditProjectSheet(project: project)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Quick Stat
struct QuickStat: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Timeline Row
struct TimelineRow: View {
    let label: String
    let date: Date
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatDate(date))
                .fontWeight(.medium)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Add Project Sheet
struct AddProjectSheet: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var propertyName = ""
    @State private var propertyAddress = ""
    @State private var purchasePrice = ""
    @State private var totalBudget = ""
    @State private var afterRepairValue = ""
    @State private var status = ProjectStatus.planning
    @State private var purchaseDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Information") {
                    TextField("Property Name", text: $propertyName)
                    TextField("Address", text: $propertyAddress)
                }
                
                Section("Financial") {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Rehab Budget", text: $totalBudget)
                        .keyboardType(.decimalPad)
                    TextField("After Repair Value (ARV)", text: $afterRepairValue)
                        .keyboardType(.decimalPad)
                }
                
                Section("Status") {
                    Picker("Project Status", selection: $status) {
                        ForEach([ProjectStatus.planning, .inProgress, .onHold], id: \.self) { s in
                            Text(s.rawValue.capitalized)
                        }
                    }
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createProject() }
                        .disabled(propertyName.isEmpty || propertyAddress.isEmpty)
                }
            }
        }
    }
    
    private func createProject() {
        var project = RehabProject()
        project.propertyName = propertyName
        project.propertyAddress = propertyAddress
        project.purchasePrice = Double(purchasePrice) ?? 0
        project.totalBudget = Double(totalBudget) ?? 0
        project.afterRepairValue = Double(afterRepairValue) ?? 0
        project.status = status
        project.purchaseDate = purchaseDate
        
        viewModel.createProject(project)
        dismiss()
    }
}

// MARK: - Edit Project Sheet
struct EditProjectSheet: View {
    let project: RehabProject
    @Environment(\.dismiss) var dismiss
    
    @State private var propertyName: String
    @State private var propertyAddress: String
    @State private var purchasePrice: String
    @State private var totalBudget: String
    @State private var afterRepairValue: String
    @State private var status: ProjectStatus
    
    init(project: RehabProject) {
        self.project = project
        _propertyName = State(initialValue: project.propertyName)
        _propertyAddress = State(initialValue: project.propertyAddress)
        _purchasePrice = State(initialValue: String(project.purchasePrice))
        _totalBudget = State(initialValue: String(project.totalBudget))
        _afterRepairValue = State(initialValue: String(project.afterRepairValue))
        _status = State(initialValue: project.status)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Property Information") {
                    TextField("Property Name", text: $propertyName)
                    TextField("Address", text: $propertyAddress)
                }
                
                Section("Financial") {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Rehab Budget", text: $totalBudget)
                        .keyboardType(.decimalPad)
                    TextField("After Repair Value", text: $afterRepairValue)
                        .keyboardType(.decimalPad)
                }
                
                Section("Status") {
                    Picker("Project Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized)
                        }
                    }
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveChanges() }
                }
            }
        }
    }
    
    private func saveChanges() {
        // Save logic
        dismiss()
    }
}

#Preview {
    ProjectsManagerView()
        .environmentObject(RehabProjectViewModel())
}
