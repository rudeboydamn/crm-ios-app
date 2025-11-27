import SwiftUI

// MARK: - Leads Manager Main View
struct LeadsManagerView: View {
    @EnvironmentObject var leadsVM: LeadViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var selectedTab: LeadsTab = .allLeads
    
    enum LeadsTab: String, CaseIterable {
        case allLeads = "All Leads"
        case pipeline = "Pipeline"
        case tasks = "Tasks"
        case campaigns = "Campaigns"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .allLeads: return "person.2.fill"
            case .pipeline: return "chart.bar.horizontal.page.fill"
            case .tasks: return "checkmark.circle.fill"
            case .campaigns: return "megaphone.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .allLeads:
                        AllLeadsListView()
                    case .pipeline:
                        LeadsPipelineView()
                    case .tasks:
                        LeadTasksView()
                    case .campaigns:
                        CampaignsView()
                    case .settings:
                        LeadSettingsView()
                    }
                }
                .environmentObject(leadsVM)
                .environmentObject(taskVM)
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(LeadsTab.allCases, id: \.self) { tab in
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
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if leadsVM.leads.isEmpty {
                leadsVM.fetchLeads()
            }
            if taskVM.tasks.isEmpty {
                taskVM.fetchTasks()
            }
        }
    }
    
    private func refreshData() {
        leadsVM.fetchLeads()
        taskVM.fetchTasks()
    }
}

// MARK: - All Leads List View
struct AllLeadsListView: View {
    @EnvironmentObject var viewModel: LeadViewModel
    @State private var showingAddLead = false
    @State private var searchText = ""
    @State private var filterStatus: LeadStatus?
    @State private var filterPriority: LeadPriority?
    @State private var selectedLead: Lead?
    
    var filteredLeads: [Lead] {
        var leads = viewModel.leads
        
        if !searchText.isEmpty {
            leads = leads.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                ($0.email ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.propertyAddress ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let status = filterStatus {
            leads = leads.filter { $0.status == status }
        }
        
        if let priority = filterPriority {
            leads = leads.filter { $0.priority == priority }
        }
        
        return leads
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filters
            VStack(spacing: 8) {
                SearchBar(text: $searchText, placeholder: "Search leads...")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Status Filters
                        Menu {
                            Button("All Status") { filterStatus = nil }
                            ForEach(LeadStatus.allCases, id: \.self) { status in
                                Button(status.rawValue.capitalized) { filterStatus = status }
                            }
                        } label: {
                            FilterLabel(
                                title: filterStatus?.rawValue.capitalized ?? "Status",
                                isActive: filterStatus != nil
                            )
                        }
                        
                        // Priority Filters
                        Menu {
                            Button("All Priority") { filterPriority = nil }
                            ForEach(LeadPriority.allCases, id: \.self) { priority in
                                Button(priority.rawValue.capitalized) { filterPriority = priority }
                            }
                        } label: {
                            FilterLabel(
                                title: filterPriority?.rawValue.capitalized ?? "Priority",
                                isActive: filterPriority != nil
                            )
                        }
                        
                        if filterStatus != nil || filterPriority != nil {
                            Button("Clear") {
                                filterStatus = nil
                                filterPriority = nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredLeads.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Leads",
                    message: "Tap + to add your first lead"
                )
            } else {
                List {
                    ForEach(filteredLeads) { lead in
                        LeadRowFull(lead: lead)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedLead = lead
                            }
                    }
                    .onDelete(perform: deleteLeads)
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddLead = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddLead) {
            AddLeadSheet()
                .environmentObject(viewModel)
        }
        .sheet(item: $selectedLead) { lead in
            LeadDetailViewFull(lead: lead)
                .environmentObject(viewModel)
        }
    }
    
    private func deleteLeads(at offsets: IndexSet) {
        for index in offsets {
            let lead = filteredLeads[index]
            viewModel.deleteLead(id: lead.id)
        }
    }
}

// MARK: - Filter Label
struct FilterLabel: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "chevron.down")
        }
        .font(.caption)
        .fontWeight(.medium)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color.blue : Color(.systemGray5))
        .foregroundColor(isActive ? .white : .primary)
        .cornerRadius(16)
    }
}

// MARK: - Lead Row Full
struct LeadRowFull: View {
    let lead: Lead
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 10, height: 10)
                
                Text(lead.fullName)
                    .font(.headline)
                
                Spacer()
                
                LeadStatusBadge(status: lead.status ?? .new)
            }
            
            if let email = lead.email {
                Label(email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let address = lead.propertyAddress {
                Label(address, systemImage: "location")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let source = lead.source {
                    Text(source.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let price = lead.askingPrice {
                    Text(formatCurrency(price))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch lead.priority {
        case .hot: return .red
        case .warm: return .orange
        case .cold: return .blue
        case .none: return .gray
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Lead Status Badge
struct LeadStatusBadge: View {
    let status: LeadStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
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
        case .new: return .blue
        case .contacted: return .orange
        case .qualified: return .purple
        case .negotiating: return .cyan
        case .underContract: return .green
        case .closed: return .green
        case .lost: return .red
        }
    }
}

// MARK: - Leads Pipeline View
struct LeadsPipelineView: View {
    @EnvironmentObject var viewModel: LeadViewModel
    
    let stages: [LeadStatus] = [.new, .contacted, .qualified, .negotiating, .underContract, .closed]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(stages, id: \.self) { stage in
                    PipelineColumn(
                        stage: stage,
                        leads: viewModel.leads.filter { $0.status == stage }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Pipeline Column
struct PipelineColumn: View {
    let stage: LeadStatus
    let leads: [Lead]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(stage.rawValue.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text("\(leads.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(stageColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(stageColor.opacity(0.2))
            .cornerRadius(8)
            
            // Leads
            if leads.isEmpty {
                Text("No leads")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(leads) { lead in
                    PipelineLeadCard(lead: lead)
                }
            }
            
            Spacer()
        }
        .frame(width: 280)
    }
    
    private var stageColor: Color {
        switch stage {
        case .new: return .blue
        case .contacted: return .orange
        case .qualified: return .purple
        case .negotiating: return .cyan
        case .underContract: return .green
        case .closed: return .green
        case .lost: return .red
        }
    }
}

// MARK: - Pipeline Lead Card
struct PipelineLeadCard: View {
    let lead: Lead
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
                
                Text(lead.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            if let address = lead.propertyAddress {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if let price = lead.askingPrice {
                Text(formatCurrency(price))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var priorityColor: Color {
        switch lead.priority {
        case .hot: return .red
        case .warm: return .orange
        case .cold: return .blue
        case .none: return .gray
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Lead Tasks View
struct LeadTasksView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var showingAddTask = false
    @State private var filterStatus: TaskStatus?
    
    var filteredTasks: [Task] {
        if let status = filterStatus {
            return taskVM.tasks.filter { $0.status == status }
        }
        return taskVM.tasks
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: filterStatus == nil) {
                        filterStatus = nil
                    }
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        FilterChip(title: status.rawValue.capitalized, isSelected: filterStatus == status) {
                            filterStatus = status
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            if taskVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredTasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Tasks",
                    message: "Tap + to create a task"
                )
            } else {
                List {
                    ForEach(filteredTasks) { task in
                        TaskRowFull(task: task)
                    }
                    .onDelete(perform: deleteTasks)
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet()
                .environmentObject(taskVM)
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            let task = filteredTasks[index]
            taskVM.deleteTask(id: task.id)
        }
    }
}

// MARK: - Task Row Full
struct TaskRowFull: View {
    let task: Task
    @EnvironmentObject var viewModel: TaskViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: { toggleComplete() }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                if let description = task.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let dueDate = task.dueDate {
                        Label(formatDate(dueDate), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? .red : .secondary)
                    }
                    
                    Spacer()
                    
                    TaskPriorityBadge(priority: task.priority)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func toggleComplete() {
        var updatedTask = task
        updatedTask.status = task.isCompleted ? .pending : .completed
        viewModel.updateTask(updatedTask)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Task Priority Badge
struct TaskPriorityBadge: View {
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

// MARK: - Campaigns View
struct CampaignsView: View {
    @State private var showingAddCampaign = false
    
    var body: some View {
        VStack {
            EmptyStateView(
                icon: "megaphone",
                title: "No Campaigns",
                message: "Create marketing campaigns to reach leads"
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddCampaign = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCampaign) {
            AddCampaignSheet()
        }
    }
}

// MARK: - Add Campaign Sheet
struct AddCampaignSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var type = "email"
    @State private var targetAudience = "all_leads"
    @State private var startDate = Date()
    
    let campaignTypes = ["email", "sms", "both"]
    let audiences = ["all_leads", "new_leads", "qualified_leads", "hot_leads"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Campaign Info") {
                    TextField("Campaign Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(campaignTypes, id: \.self) { t in
                            Text(t.uppercased())
                        }
                    }
                    
                    Picker("Target Audience", selection: $targetAudience) {
                        ForEach(audiences, id: \.self) { a in
                            Text(a.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                }
                
                Section("Schedule") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("New Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createCampaign() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func createCampaign() {
        // Create campaign logic
        dismiss()
    }
}

// MARK: - Lead Settings View
struct LeadSettingsView: View {
    @State private var autoAssignLeads = false
    @State private var leadNotifications = true
    @State private var defaultPriority = "warm"
    @State private var followUpDays = 3
    
    var body: some View {
        Form {
            Section("Lead Assignment") {
                Toggle("Auto-assign New Leads", isOn: $autoAssignLeads)
            }
            
            Section("Notifications") {
                Toggle("Lead Notifications", isOn: $leadNotifications)
            }
            
            Section("Defaults") {
                Picker("Default Priority", selection: $defaultPriority) {
                    Text("Hot").tag("hot")
                    Text("Warm").tag("warm")
                    Text("Cold").tag("cold")
                }
                
                Stepper("Follow-up Days: \(followUpDays)", value: $followUpDays, in: 1...14)
            }
            
            Section("Data") {
                Button("Export Leads") {
                    // Export logic
                }
                Button("Import Leads") {
                    // Import logic
                }
            }
        }
    }
}

// MARK: - Lead Detail View Full
struct LeadDetailViewFull: View {
    let lead: Lead
    @EnvironmentObject var viewModel: LeadViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingEdit = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Circle()
                                .fill(priorityColor)
                                .frame(width: 12, height: 12)
                            Text(lead.fullName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        LeadStatusBadge(status: lead.status ?? .new)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Contact Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Information")
                            .font(.headline)
                        
                        if let email = lead.email {
                            DetailRowView(label: "Email", value: email)
                        }
                        if let phone = lead.phone {
                            DetailRowView(label: "Phone", value: phone)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Property Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Property Information")
                            .font(.headline)
                        
                        if let address = lead.propertyAddress {
                            DetailRowView(label: "Address", value: address)
                        }
                        if let city = lead.propertyCity {
                            DetailRowView(label: "City", value: city)
                        }
                        if let state = lead.propertyState {
                            DetailRowView(label: "State", value: state)
                        }
                        if let price = lead.askingPrice {
                            DetailRowView(label: "Asking Price", value: formatCurrency(price))
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Lead Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Lead Details")
                            .font(.headline)
                        
                        if let source = lead.source {
                            DetailRowView(label: "Source", value: source.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                        if let priority = lead.priority {
                            DetailRowView(label: "Priority", value: priority.rawValue.capitalized)
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
            .navigationTitle("Lead Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") { showingEdit = true }
                }
            }
            .sheet(isPresented: $showingEdit) {
                EditLeadSheet(lead: lead)
                    .environmentObject(viewModel)
            }
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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Add Lead Sheet
struct AddLeadSheet: View {
    @EnvironmentObject var viewModel: LeadViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var propertyAddress = ""
    @State private var propertyCity = ""
    @State private var propertyState = ""
    @State private var propertyZip = ""
    @State private var askingPrice = ""
    @State private var source = LeadSource.webForm
    @State private var priority = LeadPriority.warm
    @State private var status = LeadStatus.new
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Property Information") {
                    TextField("Property Address", text: $propertyAddress)
                    TextField("City", text: $propertyCity)
                    TextField("State", text: $propertyState)
                    TextField("ZIP Code", text: $propertyZip)
                    TextField("Asking Price", text: $askingPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section("Lead Details") {
                    Picker("Source", selection: $source) {
                        ForEach(LeadSource.allCases, id: \.self) { s in
                            Text(s.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(LeadPriority.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(LeadStatus.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized)
                        }
                    }
                }
            }
            .navigationTitle("Add Lead")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveLead() }
                        .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
    
    private func saveLead() {
        let lead = Lead(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            hubspotId: nil,
            firstName: firstName,
            lastName: lastName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            source: source,
            status: status,
            priority: priority,
            tags: nil,
            propertyAddress: propertyAddress.isEmpty ? nil : propertyAddress,
            propertyCity: propertyCity.isEmpty ? nil : propertyCity,
            propertyState: propertyState.isEmpty ? nil : propertyState,
            propertyZip: propertyZip.isEmpty ? nil : propertyZip,
            askingPrice: Double(askingPrice),
            offerAmount: nil,
            arv: nil
        )
        viewModel.createLead(lead)
        dismiss()
    }
}

// MARK: - Edit Lead Sheet
struct EditLeadSheet: View {
    let lead: Lead
    @EnvironmentObject var viewModel: LeadViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var propertyAddress: String
    @State private var status: LeadStatus
    @State private var priority: LeadPriority
    
    init(lead: Lead) {
        self.lead = lead
        _firstName = State(initialValue: lead.firstName)
        _lastName = State(initialValue: lead.lastName)
        _email = State(initialValue: lead.email ?? "")
        _phone = State(initialValue: lead.phone ?? "")
        _propertyAddress = State(initialValue: lead.propertyAddress ?? "")
        _status = State(initialValue: lead.status ?? .new)
        _priority = State(initialValue: lead.priority ?? .warm)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Contact Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                }
                
                Section("Property") {
                    TextField("Property Address", text: $propertyAddress)
                }
                
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(LeadStatus.allCases, id: \.self) { s in
                            Text(s.rawValue.capitalized)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(LeadPriority.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized)
                        }
                    }
                }
            }
            .navigationTitle("Edit Lead")
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
        var updatedLead = lead
        updatedLead.firstName = firstName
        updatedLead.lastName = lastName
        updatedLead.email = email.isEmpty ? nil : email
        updatedLead.phone = phone.isEmpty ? nil : phone
        updatedLead.propertyAddress = propertyAddress.isEmpty ? nil : propertyAddress
        updatedLead.status = status
        updatedLead.priority = priority
        
        viewModel.updateLead(updatedLead)
        dismiss()
    }
}

// MARK: - Add Task Sheet
struct AddTaskSheet: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var priority = TaskPriority.medium
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description)
                }
                
                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { createTask() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func createTask() {
        let task = Task(
            id: UUID().uuidString,
            title: title,
            description: description.isEmpty ? nil : description,
            status: .pending,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            completedAt: nil,
            assignedTo: nil,
            relatedLeadId: nil,
            relatedProjectId: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        viewModel.createTask(task)
        dismiss()
    }
}

#Preview {
    LeadsManagerView()
        .environmentObject(LeadViewModel())
        .environmentObject(TaskViewModel())
}
