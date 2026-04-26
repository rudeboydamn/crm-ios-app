import SwiftUI

struct ClientsListView: View {
    @StateObject private var viewModel: ClientViewModel
    @State private var showingAddClient = false
    @State private var selectedClient: Client?
    @State private var showingFilters = false
    
    init() {
        _viewModel = StateObject(wrappedValue: ClientViewModel())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading && viewModel.clients.isEmpty {
                    ProgressView("Loading clients...")
                } else if viewModel.clients.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "No Clients Yet",
                        message: "Add your first client to get started"
                    )
                } else {
                    List {
                        if !viewModel.searchText.isEmpty || viewModel.selectedType != nil || viewModel.selectedStatus != nil {
                            Section {
                                FilterSummaryView(viewModel: viewModel)
                            }
                        }
                        
                        ForEach(viewModel.filteredClients) { client in
                            NavigationLink(destination: ClientDetailView(client: client, viewModel: viewModel)) {
                                ClientRow(client: client)
                            }
                        }
                        .onDelete(perform: deleteClients)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $viewModel.searchText, prompt: "Search clients...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClient = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                ClientFiltersView(viewModel: viewModel)
            }
            .onAppear {
                if viewModel.clients.isEmpty {
                    viewModel.fetchClients()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func deleteClients(at offsets: IndexSet) {
        for index in offsets {
            let client = viewModel.filteredClients[index]
            viewModel.deleteClient(client)
        }
    }
}

struct ClientRow: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor(client.status))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.displayName)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label(client.email, systemImage: "envelope")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !client.phone.isEmpty {
                        Label(client.phone, systemImage: "phone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(client.type.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor(client.type).opacity(0.2))
                    .foregroundColor(typeColor(client.type))
                    .cornerRadius(4)
                
                if let value = client.totalValue {
                    Text("$\(Int(value))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: ClientStatus) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .gray
        case .prospect: return .blue
        case .archived: return .red
        }
    }
    
    private func typeColor(_ type: ClientType) -> Color {
        switch type {
        case .seller: return .orange
        case .buyer: return .blue
        case .investor: return .purple
        case .partner: return .green
        case .vendor: return .cyan
        case .other: return .gray
        }
    }
}

struct ClientDetailView: View {
    let client: Client
    @ObservedObject var viewModel: ClientViewModel
    @State private var showingEdit = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(client.displayName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(client.type.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Contact Information
                GroupBox(label: Label("Contact Information", systemImage: "person.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        InfoRow(label: "Email", value: client.email, icon: "envelope")
                        InfoRow(label: "Phone", value: client.phone, icon: "phone")
                        if let secondaryPhone = client.secondaryPhone {
                            InfoRow(label: "Secondary Phone", value: secondaryPhone, icon: "phone.fill")
                        }
                    }
                }
                
                // Address
                if let address = client.address {
                    GroupBox(label: Label("Address", systemImage: "location.fill")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(address)
                            if let city = client.city, let state = client.state, let zip = client.zipCode {
                                Text("\(city), \(state) \(zip)")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Stats
                GroupBox(label: Label("Statistics", systemImage: "chart.bar.fill")) {
                    VStack(spacing: 12) {
                        if let totalProjects = client.totalProjects {
                            StatRow(label: "Total Projects", value: "\(totalProjects)")
                        }
                        if let totalLeads = client.totalLeads {
                            StatRow(label: "Total Leads", value: "\(totalLeads)")
                        }
                        if let totalValue = client.totalValue {
                            StatRow(label: "Total Value", value: "$\(Int(totalValue))")
                        }
                    }
                }
                
                // Notes
                if let notes = client.notes, !notes.isEmpty {
                    GroupBox(label: Label("Notes", systemImage: "note.text")) {
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Client Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditClientView(client: client, viewModel: viewModel)
        }
    }
}

struct AddClientView: View {
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var type: ClientType = .seller
    @State private var status: ClientStatus = .prospect
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Company (Optional)", text: $company)
                }
                
                Section("Contact") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Classification") {
                    Picker("Type", selection: $type) {
                        ForEach(ClientType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(ClientStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
                
                Section("Address (Optional)") {
                    TextField("Street Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                Section("Notes (Optional)") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveClient()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || phone.isEmpty)
                }
            }
        }
    }
    
    private func saveClient() {
        let client = Client(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            firstName: firstName,
            lastName: lastName,
            company: company.isEmpty ? nil : company,
            email: email,
            phone: phone,
            secondaryPhone: nil,
            type: type,
            status: status,
            source: nil,
            tags: [],
            address: address.isEmpty ? nil : address,
            city: city.isEmpty ? nil : city,
            state: state.isEmpty ? nil : state,
            zipCode: zipCode.isEmpty ? nil : zipCode,
            totalValue: nil,
            totalProjects: nil,
            totalLeads: nil,
            notes: notes.isEmpty ? nil : notes,
            lastContactDate: nil,
            nextFollowUpDate: nil,
            assignedTo: nil,
            leadId: nil
        )
        
        viewModel.createClient(client)
        dismiss()
    }
}

struct EditClientView: View {
    let client: Client
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var company: String
    @State private var email: String
    @State private var phone: String
    @State private var type: ClientType
    @State private var status: ClientStatus
    @State private var notes: String
    
    init(client: Client, viewModel: ClientViewModel) {
        self.client = client
        self.viewModel = viewModel
        _firstName = State(initialValue: client.firstName)
        _lastName = State(initialValue: client.lastName)
        _company = State(initialValue: client.company ?? "")
        _email = State(initialValue: client.email)
        _phone = State(initialValue: client.phone)
        _type = State(initialValue: client.type)
        _status = State(initialValue: client.status)
        _notes = State(initialValue: client.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Company", text: $company)
                }
                
                Section("Contact") {
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                }
                
                Section("Classification") {
                    Picker("Type", selection: $type) {
                        ForEach(ClientType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(ClientStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedClient = client
        updatedClient.firstName = firstName
        updatedClient.lastName = lastName
        updatedClient.company = company.isEmpty ? nil : company
        updatedClient.email = email
        updatedClient.phone = phone
        updatedClient.type = type
        updatedClient.status = status
        updatedClient.notes = notes.isEmpty ? nil : notes
        updatedClient.updatedAt = Date()
        
        viewModel.updateClient(updatedClient)
        dismiss()
    }
}

struct ClientFiltersView: View {
    @ObservedObject var viewModel: ClientViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Type") {
                    Picker("Client Type", selection: $viewModel.selectedType) {
                        Text("All Types").tag(nil as ClientType?)
                        ForEach(ClientType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type as ClientType?)
                        }
                    }
                }
                
                Section("Status") {
                    Picker("Client Status", selection: $viewModel.selectedStatus) {
                        Text("All Statuses").tag(nil as ClientStatus?)
                        ForEach(ClientStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status as ClientStatus?)
                        }
                    }
                }
                
                Section {
                    Button("Clear All Filters") {
                        viewModel.clearFilters()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterSummaryView: View {
    @ObservedObject var viewModel: ClientViewModel
    
    var body: some View {
        HStack {
            Text("Filters Active")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Clear") {
                viewModel.clearFilters()
            }
            .font(.caption)
        }
    }
}

// Reusable Components
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}
