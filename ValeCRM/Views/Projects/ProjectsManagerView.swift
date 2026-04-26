import SwiftUI

// MARK: - Projects Manager Main View
@available(iOS 16.0, *)
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
                        ProjectsListView()
                    case .pastProjects:
                        ProjectsListView()
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
        let rois = viewModel.projects.map { $0.projectedROI ?? $0.roi ?? 0 }
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

// MARK: - Project Reports View
struct ProjectReportsView: View {
    var body: some View {
        Text("Project Reports - Coming Soon")
            .foregroundColor(.secondary)
    }
}

// MARK: - Project Settings View
struct ProjectSettingsView: View {
    var body: some View {
        Text("Project Settings - Coming Soon")
            .foregroundColor(.secondary)
    }
}
