import SwiftUI

struct ProjectsListView: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    @State private var showingAddProject = false
    @State private var selectedProject: RehabProject?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ProjectsDashboardSection(totalBudget: viewModel.totalBudget,
                                             totalSpent: viewModel.totalSpent,
                                             totalRemaining: viewModel.totalRemaining,
                                             averageUtilization: viewModel.averageBudgetUtilization)
                    
                    ProjectListSection(
                        title: "Active Projects",
                        subtitle: "Work in progress",
                        projects: viewModel.activeProjects,
                        emptyMessage: "No active rehabs right now.",
                        onSelect: { selectedProject = $0 }
                    )
                    
                    ProjectListSection(
                        title: "Completed Projects",
                        subtitle: "Recently delivered rehabs",
                        projects: completedProjects,
                        emptyMessage: "No completed projects yet.",
                        onSelect: { selectedProject = $0 }
                    )
                    
                    ProjectsQuickActionsSection()
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProject = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.fetchProjects) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedProject) { project in
                ProjectDetailView(project: project)
                    .environmentObject(viewModel)
            }
            .onAppear {
                if viewModel.projects.isEmpty {
                    viewModel.fetchProjects()
                }
            }
        }
    }

    private var completedProjects: [RehabProject] {
        viewModel.projects.filter { project in
            project.status.lowercased().contains("completed")
        }
    }
}

private struct EmphasizedDetailModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.fontWeight(.semibold)
        } else {
            content
        }
    }
}

private extension View {
    func emphasizedDetail() -> some View {
        self.modifier(EmphasizedDetailModifier())
    }
}

struct ProjectsDashboardSection: View {
    let totalBudget: Double
    let totalSpent: Double
    let totalRemaining: Double
    let averageUtilization: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Overview")
                .font(.title2)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ProjectMetricCard(title: "Total Budget",
                                       value: formatCurrency(totalBudget),
                                       icon: "dollarsign.circle.fill",
                                       color: .blue)
                    ProjectMetricCard(title: "Total Spent",
                                       value: formatCurrency(totalSpent),
                                       icon: "arrow.down.circle.fill",
                                       color: .orange)
                    ProjectMetricCard(title: "Remaining",
                                       value: formatCurrency(totalRemaining),
                                       icon: "banknote.fill",
                                       color: .green)
                    ProjectMetricCard(title: "Avg Utilization",
                                       value: String(format: "%.1f%%", averageUtilization),
                                       icon: "chart.pie.fill",
                                       color: .purple)
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct ProjectMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ProjectRowView: View {
    let project: RehabProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(project.displayName)
                    .font(.headline)
                Spacer()
                ProjectStatusBadge(status: project.status)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(project.totalBudget, default: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(project.totalSpent, default: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(project.remainingBudget, default: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(project.remainingBudget > 0 ? .green : .red)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor(for: project.budgetUtilization))
                        .frame(width: geometry.size.width * CGFloat(min(project.budgetUtilization / 100, 1.0)), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(project.budgetUtilization, default: "%.1f")% utilized")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func progressColor(for utilization: Double) -> Color {
        switch utilization {
        case 0..<50:
            return .green
        case 50..<80:
            return .orange
        default:
            return .red
        }
    }
}

struct ProjectListSection: View {
    let title: String
    let subtitle: String
    let projects: [RehabProject]
    let emptyMessage: String
    let onSelect: (RehabProject) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if projects.isEmpty {
                Text(emptyMessage)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(projects) { project in
                        Button(action: { onSelect(project) }) {
                            ProjectRowView(project: project)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
    }
}

struct ProjectsQuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                quickAction(title: "Reports", subtitle: "View analytics", icon: "chart.xyaxis.line", color: .blue)
                quickAction(title: "Settings", subtitle: "Configure projects", icon: "gear", color: .gray)
                quickAction(title: "Share", subtitle: "Export data", icon: "square.and.arrow.up", color: .green)
                quickAction(title: "Docs", subtitle: "Upload files", icon: "doc.fill", color: .orange)
            }
        }
    }
    
    @ViewBuilder
    private func quickAction(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ProjectStatusBadge: View {
    let status: String?
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        guard let status = status?.lowercased() else { return .gray }
        if status.contains("planning") { return .blue }
        if status.contains("active") { return .green }
        if status.contains("hold") { return .orange }
        if status.contains("completed") { return .purple }
        if status.contains("cancelled") { return .red }
        return .gray
    }
    
    private var statusText: String {
        status?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown"
    }
}

struct AddProjectView: View {
    @EnvironmentObject var viewModel: RehabProjectViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var propertyAddress = ""
    @State private var propertyName = ""
    @State private var status: String = ProjectStatus.planning.rawValue
    @State private var totalBudget = ""
    @State private var totalRehabCosts = ""
    @State private var startDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Information")) {
                    TextField("Property Name", text: $propertyName)
                    TextField("Property Address", text: $propertyAddress)
                    
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { statusCase in
                            Text(statusCase.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(statusCase.rawValue)
                        }
                    }
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                Section(header: Text("Budget")) {
                    TextField("Total Purchase / Holding Budget", text: $totalBudget)
                        .keyboardType(.decimalPad)
                    
                    TextField("Total Rehab Costs", text: $totalRehabCosts)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Project")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProject()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        !propertyAddress.isEmpty && !totalBudget.isEmpty
    }
    
    private func saveProject() {
        var project = RehabProject()
        project.propertyName = propertyName
        project.propertyAddress = propertyAddress
        project.status = status
        project.purchaseDate = isoFormatter.string(from: startDate)
        project.totalPurchaseCosts = Double(totalBudget)
        project.totalRehabCosts = Double(totalRehabCosts)
        
        viewModel.createProject(project)
        presentationMode.wrappedValue.dismiss()
    }
    
    private var isoFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

struct ProjectDetailView: View {
    let project: RehabProject
    @EnvironmentObject var viewModel: RehabProjectViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            List {
                // Project Overview
                Section(header: Text("Project Overview")) {
                    DetailRow(label: "Property Name", value: project.propertyName.isEmpty ? "—" : project.propertyName)
                    DetailRow(label: "Address", value: project.propertyAddress)
                    HStack {
                        Text("Status")
                            .foregroundColor(.secondary)
                        Spacer()
                        ProjectStatusBadge(status: project.status)
                    }
                    if let sqft = project.measuredSqft {
                        DetailRow(label: "Square Footage", value: "\(Int(sqft)) sqft")
                    }
                    if let rehabType = project.rehabType {
                        DetailRow(label: "Rehab Type", value: rehabType)
                    }
                }
                
                // Timeline
                Section(header: Text("Timeline")) {
                    if let startDate = project.startDate {
                        DetailRow(label: "Purchase Date", value: startDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    if let completionDate = project.completionDate {
                        DetailRow(label: "Sell Date", value: completionDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                
                // Financial Summary
                Section(header: Text("Financial Summary")) {
                    if let revenue = project.salesRevenue {
                        DetailRow(label: "Sales Revenue", value: formatCurrency(revenue))
                    }
                    if let investment = project.totalInvestment {
                        DetailRow(label: "Total Investment", value: formatCurrency(investment))
                    }
                    if let netIncome = project.netIncome {
                        DetailRow(label: "Net Income", value: formatCurrency(netIncome))
                    }
                    if let roi = project.roi {
                        HStack {
                            Text("ROI")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(roi, specifier: "%.1f")%")
                                .fontWeight(.semibold)
                                .foregroundColor(roi > 0 ? .green : .red)
                        }
                    }
                }
                
                // Purchase Costs
                Section(header: Text("Purchase Costs")) {
                    if let cost = project.propertyPurchase {
                        DetailRow(label: "Property Purchase", value: formatCurrency(cost))
                    }
                    if let cost = project.homeInspection {
                        DetailRow(label: "Home Inspection", value: formatCurrency(cost))
                    }
                    if let cost = project.appraisal {
                        DetailRow(label: "Appraisal", value: formatCurrency(cost))
                    }
                    if let cost = project.survey {
                        DetailRow(label: "Survey", value: formatCurrency(cost))
                    }
                    if let cost = project.lenderFees {
                        DetailRow(label: "Lender Fees", value: formatCurrency(cost))
                    }
                    if let cost = project.purchaseClosingCosts {
                        DetailRow(label: "Closing Costs", value: formatCurrency(cost))
                    }
                    if let cost = project.purchaseOther {
                        DetailRow(label: "Other", value: formatCurrency(cost))
                    }
                    if let total = project.totalPurchaseCosts {
                        DetailRow(label: "Total Purchase Costs", value: formatCurrency(total))
                            .emphasizedDetail()
                    }
                }
                
                // Rehab Costs
                Section(header: Text("Rehab Costs")) {
                    if let cost = project.totalContractor {
                        DetailRow(label: "Contractor Costs", value: formatCurrency(cost))
                    }
                    if let cost = project.totalMaterials {
                        DetailRow(label: "Materials", value: formatCurrency(cost))
                    }
                    if let total = project.totalRehabCosts {
                        DetailRow(label: "Total Rehab Costs", value: formatCurrency(total))
                            .emphasizedDetail()
                    }
                }
                
                // Holding Costs
                Section(header: Text("Holding Costs")) {
                    if let cost = project.mortgageInterest {
                        DetailRow(label: "Mortgage Interest", value: formatCurrency(cost))
                    }
                    if let cost = project.investorMortgageInterest {
                        DetailRow(label: "Investor Mortgage Interest", value: formatCurrency(cost))
                    }
                    if let cost = project.propertyTaxes {
                        DetailRow(label: "Property Taxes", value: formatCurrency(cost))
                    }
                    if let cost = project.insurance {
                        DetailRow(label: "Insurance", value: formatCurrency(cost))
                    }
                    if let cost = project.totalUtilities {
                        DetailRow(label: "Utilities", value: formatCurrency(cost))
                    }
                    if let cost = project.lawnCare {
                        DetailRow(label: "Lawn Care", value: formatCurrency(cost))
                    }
                    if let cost = project.holdingOther {
                        DetailRow(label: "Other", value: formatCurrency(cost))
                    }
                    if let total = project.totalHoldingCosts {
                        DetailRow(label: "Total Holding Costs", value: formatCurrency(total))
                            .emphasizedDetail()
                    }
                }
                
                // Selling Costs
                Section(header: Text("Selling Costs")) {
                    if let percent = project.brokerCommissionPercent {
                        DetailRow(label: "Broker Commission", value: "\(percent, default: "%.1f")%")
                    }
                    if let cost = project.homeWarranty {
                        DetailRow(label: "Home Warranty", value: formatCurrency(cost))
                    }
                    if let cost = project.buyerTermite {
                        DetailRow(label: "Buyer Termite", value: formatCurrency(cost))
                    }
                    if let cost = project.closingCostsBuyer {
                        DetailRow(label: "Closing Costs (Buyer)", value: formatCurrency(cost))
                    }
                    if let cost = project.sellingClosingCosts {
                        DetailRow(label: "Selling Closing Costs", value: formatCurrency(cost))
                    }
                    if let total = project.totalSellingCosts {
                        DetailRow(label: "Total Selling Costs", value: formatCurrency(total))
                            .emphasizedDetail()
                    }
                }

                
                // Actions
                Section {
                    Button(action: {
                        isEditing = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Edit Project")
                            Spacer()
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        viewModel.deleteProject(project)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Project")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(project.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $isEditing) {
                EditProjectView(project: project)
                    .environmentObject(viewModel)
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        return String(format: "$%.2f", value)
    }
}
