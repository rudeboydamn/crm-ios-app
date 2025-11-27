import SwiftUI

// MARK: - Communications Hub Main View
struct CommunicationsHubView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var selectedTab: CommsTab = .contacts
    
    enum CommsTab: String, CaseIterable {
        case contacts = "Contacts"
        case email = "Email"
        case sms = "SMS"
        case calls = "Call Log"
        case templates = "Templates"
        case analytics = "Analytics"
        case history = "History"
        
        var icon: String {
            switch self {
            case .contacts: return "person.crop.circle.fill"
            case .email: return "envelope.fill"
            case .sms: return "message.fill"
            case .calls: return "phone.fill"
            case .templates: return "doc.text.fill"
            case .analytics: return "chart.bar.fill"
            case .history: return "clock.arrow.circlepath"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .contacts:
                        ContactsListView()
                    case .email:
                        EmailComposeView()
                    case .sms:
                        SMSComposeView()
                    case .calls:
                        CallLogView()
                    case .templates:
                        TemplatesListView()
                    case .analytics:
                        CommsAnalyticsView()
                    case .history:
                        CommsHistoryView()
                    }
                }
                .environmentObject(viewModel)
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(CommsTab.allCases, id: \.self) { tab in
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
                    Button(action: { viewModel.fetchCommunications() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            viewModel.fetchCommunications()
            viewModel.fetchContacts()
        }
    }
}

// MARK: - Contacts List View
struct ContactsListView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var showingAddContact = false
    @State private var searchText = ""
    @State private var selectedFilter: ContactFilter = .all
    
    enum ContactFilter: String, CaseIterable {
        case all = "All"
        case leads = "Leads"
        case clients = "Clients"
        case vendors = "Vendors"
    }
    
    var filteredContacts: [CommunicationContact] {
        var contacts = viewModel.contacts
        
        if !searchText.isEmpty {
            contacts = contacts.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                ($0.email ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedFilter != .all {
            contacts = contacts.filter { ($0.type ?? "").lowercased() == selectedFilter.rawValue.lowercased() }
        }
        
        return contacts
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter
            VStack(spacing: 8) {
                SearchBar(text: $searchText, placeholder: "Search contacts...")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ContactFilter.allCases, id: \.self) { filter in
                            FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredContacts.isEmpty {
                EmptyStateView(
                    icon: "person.crop.circle",
                    title: "No Contacts",
                    message: "Add contacts to start communicating"
                )
            } else {
                List {
                    ForEach(filteredContacts) { contact in
                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                            ContactRowView(contact: contact)
                        }
                    }
                    .onDelete(perform: deleteContacts)
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddContact = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddContactSheet()
                .environmentObject(viewModel)
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        // Delete logic
    }
}

// MARK: - Contact Row View
struct ContactRowView: View {
    let contact: CommunicationContact
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(contactTypeColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(contact.initials)
                        .font(.headline)
                        .foregroundColor(contactTypeColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.fullName)
                    .font(.headline)
                
                if let email = contact.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let type = contact.type {
                    Text(type.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(contactTypeColor.opacity(0.2))
                        .foregroundColor(contactTypeColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var contactTypeColor: Color {
        switch (contact.type ?? "").lowercased() {
        case "lead": return .blue
        case "client": return .green
        case "vendor": return .orange
        default: return .gray
        }
    }
}

// MARK: - Contact Detail View
struct ContactDetailView: View {
    let contact: CommunicationContact
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var showingEmail = false
    @State private var showingSMS = false
    @State private var showingCall = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(contact.initials)
                                .font(.title)
                                .foregroundColor(.blue)
                        )
                    
                    Text(contact.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let company = contact.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Quick Actions
                HStack(spacing: 20) {
                    QuickActionButton(icon: "envelope.fill", label: "Email", color: .blue) {
                        showingEmail = true
                    }
                    QuickActionButton(icon: "message.fill", label: "SMS", color: .green) {
                        showingSMS = true
                    }
                    QuickActionButton(icon: "phone.fill", label: "Call", color: .orange) {
                        showingCall = true
                    }
                }
                .padding(.horizontal)
                
                // Contact Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Information")
                        .font(.headline)
                    
                    if let email = contact.email {
                        ContactInfoRow(icon: "envelope", label: "Email", value: email)
                    }
                    if let phone = contact.phone {
                        ContactInfoRow(icon: "phone", label: "Phone", value: phone)
                    }
                    if let company = contact.company {
                        ContactInfoRow(icon: "building.2", label: "Company", value: company)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Communication History
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Communications")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.communications.isEmpty {
                        EmptyStateView(
                            icon: "bubble.left.and.bubble.right",
                            title: "No History",
                            message: "Communications will appear here"
                        )
                        .frame(height: 150)
                    } else {
                        ForEach(viewModel.communications.prefix(5)) { comm in
                            CommunicationHistoryRow(communication: comm)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEmail) {
            EmailComposeSheet(recipient: contact)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingSMS) {
            SMSComposeSheet(recipient: contact)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingCall) {
            CallLogSheet(contact: contact)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .cornerRadius(25)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Contact Info Row
struct ContactInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
}

// MARK: - Communication History Row
struct CommunicationHistoryRow: View {
    let communication: Communication
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .foregroundColor(typeColor)
                .frame(width: 32, height: 32)
                .background(typeColor.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(communication.subject ?? communication.type.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let date = communication.date {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(communication.status?.capitalized ?? "Sent")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var typeIcon: String {
        switch communication.type {
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .call: return "phone.fill"
        case .meeting: return "calendar"
        case .note: return "note.text"
        }
    }
    
    private var typeColor: Color {
        switch communication.type {
        case .email: return .blue
        case .sms: return .green
        case .call: return .orange
        case .meeting: return .purple
        case .note: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Email Compose View
struct EmailComposeView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var showingCompose = false
    
    var emailComms: [Communication] {
        viewModel.communications.filter { $0.type == .email }
    }
    
    var body: some View {
        VStack {
            if emailComms.isEmpty {
                EmptyStateView(
                    icon: "envelope",
                    title: "No Emails",
                    message: "Tap + to compose an email"
                )
            } else {
                List {
                    ForEach(emailComms) { comm in
                        CommunicationHistoryRow(communication: comm)
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCompose = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingCompose) {
            EmailComposeSheet(recipient: nil)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Email Compose Sheet
struct EmailComposeSheet: View {
    let recipient: CommunicationContact?
    @EnvironmentObject var viewModel: CommunicationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var toEmail = ""
    @State private var subject = ""
    @State private var body = ""
    @State private var selectedTemplate: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("To", text: $toEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Subject", text: $subject)
                }
                
                Section("Template") {
                    Picker("Use Template", selection: $selectedTemplate) {
                        Text("None").tag(String?.none)
                        ForEach(viewModel.templates) { template in
                            Text(template.name).tag(template.id as String?)
                        }
                    }
                }
                
                Section("Message") {
                    TextEditor(text: $body)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Compose Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") { sendEmail() }
                        .disabled(toEmail.isEmpty || subject.isEmpty)
                }
            }
            .onAppear {
                if let contact = recipient {
                    toEmail = contact.email ?? ""
                }
            }
        }
    }
    
    private func sendEmail() {
        viewModel.sendEmail(to: toEmail, subject: subject, body: body)
        dismiss()
    }
}

// MARK: - SMS Compose View
struct SMSComposeView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var showingCompose = false
    
    var smsComms: [Communication] {
        viewModel.communications.filter { $0.type == .sms }
    }
    
    var body: some View {
        VStack {
            if smsComms.isEmpty {
                EmptyStateView(
                    icon: "message",
                    title: "No SMS Messages",
                    message: "Tap + to send an SMS"
                )
            } else {
                List {
                    ForEach(smsComms) { comm in
                        CommunicationHistoryRow(communication: comm)
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCompose = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingCompose) {
            SMSComposeSheet(recipient: nil)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - SMS Compose Sheet
struct SMSComposeSheet: View {
    let recipient: CommunicationContact?
    @EnvironmentObject var viewModel: CommunicationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var toPhone = ""
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Phone Number", text: $toPhone)
                        .keyboardType(.phonePad)
                }
                
                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                    
                    HStack {
                        Spacer()
                        Text("\(message.count)/160")
                            .font(.caption)
                            .foregroundColor(message.count > 160 ? .red : .secondary)
                    }
                }
            }
            .navigationTitle("Send SMS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") { sendSMS() }
                        .disabled(toPhone.isEmpty || message.isEmpty)
                }
            }
            .onAppear {
                if let contact = recipient {
                    toPhone = contact.phone ?? ""
                }
            }
        }
    }
    
    private func sendSMS() {
        viewModel.sendSMS(to: toPhone, message: message)
        dismiss()
    }
}

// MARK: - Call Log View
struct CallLogView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var showingLogCall = false
    
    var callComms: [Communication] {
        viewModel.communications.filter { $0.type == .call }
    }
    
    var body: some View {
        VStack {
            if callComms.isEmpty {
                EmptyStateView(
                    icon: "phone",
                    title: "No Call Logs",
                    message: "Tap + to log a call"
                )
            } else {
                List {
                    ForEach(callComms) { comm in
                        CallLogRow(communication: comm)
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingLogCall = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingLogCall) {
            CallLogSheet(contact: nil)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Call Log Row
struct CallLogRow: View {
    let communication: Communication
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: callDirectionIcon)
                .foregroundColor(callDirectionColor)
                .frame(width: 32, height: 32)
                .background(callDirectionColor.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(communication.contactName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    if let duration = communication.duration {
                        Text("\(duration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let date = communication.date {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if let notes = communication.notes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var callDirectionIcon: String {
        return "phone.arrow.up.right.fill"
    }
    
    private var callDirectionColor: Color {
        return .green
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Call Log Sheet
struct CallLogSheet: View {
    let contact: CommunicationContact?
    @EnvironmentObject var viewModel: CommunicationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var contactName = ""
    @State private var phoneNumber = ""
    @State private var duration = ""
    @State private var callDate = Date()
    @State private var outcome = "completed"
    @State private var notes = ""
    
    let outcomes = ["completed", "no_answer", "voicemail", "busy", "callback_requested"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Call Details") {
                    TextField("Contact Name", text: $contactName)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Duration (minutes)", text: $duration)
                        .keyboardType(.numberPad)
                    DatePicker("Date & Time", selection: $callDate)
                }
                
                Section("Outcome") {
                    Picker("Call Outcome", selection: $outcome) {
                        ForEach(outcomes, id: \.self) { o in
                            Text(o.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveCallLog() }
                        .disabled(contactName.isEmpty)
                }
            }
            .onAppear {
                if let c = contact {
                    contactName = c.fullName
                    phoneNumber = c.phone ?? ""
                }
            }
        }
    }
    
    private func saveCallLog() {
        viewModel.logCall(
            contactName: contactName,
            phone: phoneNumber,
            duration: Int(duration) ?? 0,
            outcome: outcome,
            notes: notes
        )
        dismiss()
    }
}

// MARK: - Templates List View
struct TemplatesListView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var showingAddTemplate = false
    
    var body: some View {
        VStack {
            if viewModel.templates.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Templates",
                    message: "Create templates for quick messaging"
                )
            } else {
                List {
                    ForEach(viewModel.templates) { template in
                        NavigationLink(destination: TemplateDetailView(template: template)) {
                            TemplateRowView(template: template)
                        }
                    }
                    .onDelete(perform: deleteTemplates)
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTemplate = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddTemplateSheet()
                .environmentObject(viewModel)
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        // Delete logic
    }
}

// MARK: - Template Row View
struct TemplateRowView: View {
    let template: CommunicationTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                Spacer()
                Text(template.type.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            if let subject = template.subject {
                Text(subject)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Template Detail View
struct TemplateDetailView: View {
    let template: CommunicationTemplate
    @State private var showingEdit = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(template.type.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Subject (if email)
                if let subject = template.subject {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.headline)
                        Text(subject)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                
                // Body
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.headline)
                    Text(template.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditTemplateSheet(template: template)
        }
    }
}

// MARK: - Add Template Sheet
struct AddTemplateSheet: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var type = "email"
    @State private var subject = ""
    @State private var body = ""
    
    let types = ["email", "sms"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Template Info") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { t in
                            Text(t.capitalized)
                        }
                    }
                }
                
                if type == "email" {
                    Section("Subject") {
                        TextField("Email Subject", text: $subject)
                    }
                }
                
                Section("Message") {
                    TextEditor(text: $body)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveTemplate() }
                        .disabled(name.isEmpty || body.isEmpty)
                }
            }
        }
    }
    
    private func saveTemplate() {
        viewModel.createTemplate(name: name, type: type, subject: type == "email" ? subject : nil, body: body)
        dismiss()
    }
}

// MARK: - Edit Template Sheet
struct EditTemplateSheet: View {
    let template: CommunicationTemplate
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String
    @State private var subject: String
    @State private var body: String
    
    init(template: CommunicationTemplate) {
        self.template = template
        _name = State(initialValue: template.name)
        _subject = State(initialValue: template.subject ?? "")
        _body = State(initialValue: template.body)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Template Info") {
                    TextField("Name", text: $name)
                }
                
                if template.type == "email" {
                    Section("Subject") {
                        TextField("Email Subject", text: $subject)
                    }
                }
                
                Section("Message") {
                    TextEditor(text: $body)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("Edit Template")
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

// MARK: - Comms Analytics View
struct CommsAnalyticsView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    AnalyticCard(
                        title: "Total Sent",
                        value: "\(viewModel.communications.count)",
                        icon: "paperplane.fill",
                        color: .blue
                    )
                    AnalyticCard(
                        title: "Emails",
                        value: "\(viewModel.communications.filter { $0.type == .email }.count)",
                        icon: "envelope.fill",
                        color: .purple
                    )
                    AnalyticCard(
                        title: "SMS",
                        value: "\(viewModel.communications.filter { $0.type == .sms }.count)",
                        icon: "message.fill",
                        color: .green
                    )
                    AnalyticCard(
                        title: "Calls",
                        value: "\(viewModel.communications.filter { $0.type == .call }.count)",
                        icon: "phone.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Response Rate
                VStack(alignment: .leading, spacing: 12) {
                    Text("Response Rate")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Overall Response Rate")
                            Spacer()
                            Text("0%")
                                .fontWeight(.bold)
                        }
                        
                        ProgressView(value: 0)
                            .tint(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Analytic Card
struct AnalyticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Comms History View
struct CommsHistoryView: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @State private var filterType: CommunicationType?
    
    var filteredComms: [Communication] {
        if let type = filterType {
            return viewModel.communications.filter { $0.type == type }
        }
        return viewModel.communications
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isSelected: filterType == nil) {
                        filterType = nil
                    }
                    ForEach([CommunicationType.email, .sms, .call], id: \.self) { type in
                        FilterChip(title: type.rawValue.capitalized, isSelected: filterType == type) {
                            filterType = type
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            if filteredComms.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    title: "No History",
                    message: "Your communication history will appear here"
                )
            } else {
                List {
                    ForEach(filteredComms) { comm in
                        CommunicationHistoryRow(communication: comm)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Add Contact Sheet
struct AddContactSheet: View {
    @EnvironmentObject var viewModel: CommunicationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var company = ""
    @State private var type = "lead"
    
    let contactTypes = ["lead", "client", "vendor", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Details") {
                    TextField("Company", text: $company)
                    Picker("Type", selection: $type) {
                        ForEach(contactTypes, id: \.self) { t in
                            Text(t.capitalized)
                        }
                    }
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveContact() }
                        .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
    
    private func saveContact() {
        viewModel.createContact(
            firstName: firstName,
            lastName: lastName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            company: company.isEmpty ? nil : company,
            type: type
        )
        dismiss()
    }
}

#Preview {
    CommunicationsHubView()
        .environmentObject(CommunicationViewModel())
}
