import SwiftUI

struct LeadsListView: View {
    @EnvironmentObject var viewModel: LeadViewModel
    @State private var showingAddLead = false
    @State private var selectedLead: Lead?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.leads.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "No Leads Yet",
                        message: "Tap the + button to add your first lead"
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredLeads) { lead in
                            LeadRowView(lead: lead)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedLead = lead
                                }
                        }
                        .onDelete(perform: deleteLeads)
                    }
                }
            }
            .navigationTitle("Leads")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddLead = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.fetchLeads) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddLead) {
                AddLeadView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedLead) { lead in
                LeadDetailView(lead: lead)
                    .environmentObject(viewModel)
            }
            .onAppear {
                if viewModel.leads.isEmpty {
                    viewModel.fetchLeads()
                }
            }
        }
    }
    
    private func deleteLeads(at offsets: IndexSet) {
        for index in offsets {
            let lead = viewModel.filteredLeads[index]
            viewModel.deleteLead(lead)
        }
    }
}

struct LeadRowView: View {
    let lead: Lead
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lead.fullName)
                    .font(.headline)
                
                Spacer()
                
                if let priority = lead.priority {
                    PriorityBadge(priority: priority)
                }
            }
            
            Text(lead.propertyAddress ?? "No address")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                if let status = lead.status {
                    StatusBadge(status: status)
                }
                Spacer()
                if let amount = lead.offerAmount {
                    Text("$\(amount, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PriorityBadge: View {
    let priority: LeadPriority
    
    var body: some View {
        Text(priority.rawValue.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .hot: return .red
        case .warm: return .orange
        case .cold: return .blue
        }
    }
}

struct StatusBadge: View {
    let status: LeadStatus
    
    var body: some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(4)
    }
}

struct AddLeadView: View {
    @EnvironmentObject var viewModel: LeadViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var propertyAddress = ""
    @State private var propertyCity = ""
    @State private var propertyState = ""
    @State private var propertyZip = ""
    @State private var source: LeadSource = .webForm
    @State private var status: LeadStatus = .new
    @State private var priority: LeadPriority = .warm
    @State private var askingPrice = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Property Information")) {
                    TextField("Address", text: $propertyAddress)
                    TextField("City", text: $propertyCity)
                    TextField("State", text: $propertyState)
                    TextField("ZIP Code", text: $propertyZip)
                        .keyboardType(.numberPad)
                    TextField("Asking Price (optional)", text: $askingPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Lead Details")) {
                    Picker("Source", selection: $source) {
                        ForEach(LeadSource.allCases, id: \.self) { source in
                            Text(source.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(LeadStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(LeadPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized)
                        }
                    }
                }
            }
            .navigationTitle("New Lead")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveLead()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !propertyAddress.isEmpty
    }
    
    private func saveLead() {
        let lead = Lead(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            hubspotId: nil,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            source: source,
            status: status,
            priority: priority,
            tags: [],
            propertyAddress: propertyAddress,
            propertyCity: propertyCity,
            propertyState: propertyState,
            propertyZip: propertyZip,
            askingPrice: Double(askingPrice),
            offerAmount: nil,
            arv: nil
        )
        
        viewModel.createLead(lead)
        presentationMode.wrappedValue.dismiss()
    }
}

struct LeadDetailView: View {
    let lead: Lead
    @EnvironmentObject var viewModel: LeadViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Contact")) {
                    DetailRow(label: "Name", value: lead.fullName)
                    DetailRow(label: "Email", value: lead.email ?? "--")
                    DetailRow(label: "Phone", value: lead.phone ?? "--")
                }
                
                Section(header: Text("Property")) {
                    DetailRow(label: "Address", value: lead.propertyAddress ?? "--")
                    DetailRow(label: "City", value: lead.propertyCity ?? "--")
                    DetailRow(label: "State", value: lead.propertyState ?? "--")
                    DetailRow(label: "ZIP", value: lead.propertyZip ?? "--")
                }
                
                Section(header: Text("Details")) {
                    DetailRow(label: "Source", value: lead.source?.rawValue.capitalized ?? "--")
                    DetailRow(label: "Status", value: lead.status?.rawValue.capitalized ?? "--")
                    DetailRow(label: "Priority", value: lead.priority?.rawValue.capitalized ?? "--")
                }
                
                if let askingPrice = lead.askingPrice {
                    Section(header: Text("Financial")) {
                        DetailRow(label: "Asking Price", value: String(format: "$%.0f", askingPrice))
                    }
                }
            }
            .navigationTitle("Lead Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
