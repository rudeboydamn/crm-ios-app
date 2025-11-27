import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: SettingsTab = .profile
    
    enum SettingsTab: String, CaseIterable {
        case profile = "Profile"
        case users = "User Management"
        case notifications = "Notifications"
        case integrations = "Integrations"
        case data = "Data & Sync"
        case about = "About"
        
        var icon: String {
            switch self {
            case .profile: return "person.circle.fill"
            case .users: return "person.2.fill"
            case .notifications: return "bell.fill"
            case .integrations: return "puzzlepiece.fill"
            case .data: return "externaldrive.fill"
            case .about: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    NavigationLink(destination: settingsDestination(for: tab)) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
                
                Section {
                    Button(action: signOut) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    @ViewBuilder
    private func settingsDestination(for tab: SettingsTab) -> some View {
        switch tab {
        case .profile:
            ProfileSettingsView()
        case .users:
            UserManagementView()
        case .notifications:
            NotificationSettingsView()
        case .integrations:
            IntegrationsSettingsView()
        case .data:
            DataSettingsView()
        case .about:
            AboutView()
        }
    }
    
    private func signOut() {
        authManager.signOut()
        dismiss()
    }
}

// MARK: - Profile Settings View
struct ProfileSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var showingChangePassword = false
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }
            
            Section("Security") {
                Button("Change Password") {
                    showingChangePassword = true
                }
            }
            
            Section {
                Button("Save Changes") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            if let user = authManager.currentUser {
                name = user.name
                email = user.email
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordSheet()
        }
    }
    
    private func saveProfile() {
        // Save profile logic
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                
                if showError {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { changePassword() }
                        .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            showError = true
            return
        }
        
        // Change password logic
        dismiss()
    }
}

// MARK: - User Management View
struct UserManagementView: View {
    @State private var users: [AppUser] = []
    @State private var pendingUsers: [AppUser] = []
    @State private var isLoading = false
    @State private var showingAddUser = false
    
    var body: some View {
        List {
            Section("Pending Approval") {
                if pendingUsers.isEmpty {
                    Text("No pending users")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(pendingUsers) { user in
                        PendingUserRow(user: user, onApprove: approveUser, onDeny: denyUser)
                    }
                }
            }
            
            Section("Active Users") {
                if users.isEmpty {
                    Text("No users")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(users) { user in
                        UserRow(user: user)
                    }
                    .onDelete(perform: deleteUsers)
                }
            }
        }
        .navigationTitle("User Management")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddUser = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddUser) {
            AddUserSheet()
        }
        .onAppear {
            fetchUsers()
        }
        .refreshable {
            fetchUsers()
        }
    }
    
    private func fetchUsers() {
        // Fetch users logic
    }
    
    private func approveUser(_ user: AppUser) {
        // Approve user logic
    }
    
    private func denyUser(_ user: AppUser) {
        // Deny user logic
    }
    
    private func deleteUsers(at offsets: IndexSet) {
        // Delete users logic
    }
}

// MARK: - App User Model
struct AppUser: Identifiable {
    let id: String
    var name: String
    var email: String
    var role: String
    var status: String
    var createdAt: Date
}

// MARK: - Pending User Row
struct PendingUserRow: View {
    let user: AppUser
    let onApprove: (AppUser) -> Void
    let onDeny: (AppUser) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: { onApprove(user) }) {
                    Text("Approve")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: { onDeny(user) }) {
                    Text("Deny")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Row
struct UserRow: View {
    let user: AppUser
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(user.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(user.role.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor.opacity(0.2))
                .foregroundColor(roleColor)
                .cornerRadius(4)
        }
    }
    
    private var roleColor: Color {
        switch user.role.lowercased() {
        case "admin": return .purple
        case "manager": return .blue
        default: return .gray
        }
    }
}

// MARK: - Add User Sheet
struct AddUserSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var role = "user"
    
    let roles = ["user", "manager", "admin"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("User Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Role") {
                    Picker("Role", selection: $role) {
                        ForEach(roles, id: \.self) { r in
                            Text(r.capitalized)
                        }
                    }
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Invite") { inviteUser() }
                        .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func inviteUser() {
        // Invite user logic
        dismiss()
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @State private var pushEnabled = true
    @State private var emailEnabled = true
    @State private var leadNotifications = true
    @State private var taskNotifications = true
    @State private var paymentNotifications = true
    @State private var projectNotifications = true
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Push Notifications", isOn: $pushEnabled)
                Toggle("Email Notifications", isOn: $emailEnabled)
            }
            
            Section("Categories") {
                Toggle("New Leads", isOn: $leadNotifications)
                Toggle("Task Reminders", isOn: $taskNotifications)
                Toggle("Payment Updates", isOn: $paymentNotifications)
                Toggle("Project Updates", isOn: $projectNotifications)
            }
        }
        .navigationTitle("Notifications")
    }
}

// MARK: - Integrations Settings View
struct IntegrationsSettingsView: View {
    @State private var hubspotConnected = false
    @State private var twilioConnected = false
    @State private var resendConnected = false
    @State private var showingHubSpotSetup = false
    
    var body: some View {
        Form {
            Section("CRM") {
                IntegrationRow(
                    name: "HubSpot",
                    icon: "link.circle.fill",
                    isConnected: hubspotConnected,
                    onToggle: { showingHubSpotSetup = true }
                )
            }
            
            Section("Communications") {
                IntegrationRow(
                    name: "Twilio (SMS)",
                    icon: "message.circle.fill",
                    isConnected: twilioConnected,
                    onToggle: { }
                )
                
                IntegrationRow(
                    name: "Resend (Email)",
                    icon: "envelope.circle.fill",
                    isConnected: resendConnected,
                    onToggle: { }
                )
            }
        }
        .navigationTitle("Integrations")
        .sheet(isPresented: $showingHubSpotSetup) {
            HubSpotSetupSheet(isConnected: $hubspotConnected)
        }
    }
}

// MARK: - Integration Row
struct IntegrationRow: View {
    let name: String
    let icon: String
    let isConnected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isConnected ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(isConnected ? "Connected" : "Not connected")
                    .font(.caption)
                    .foregroundColor(isConnected ? .green : .secondary)
            }
            
            Spacer()
            
            Button(action: onToggle) {
                Text(isConnected ? "Manage" : "Connect")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - HubSpot Setup Sheet
struct HubSpotSetupSheet: View {
    @Binding var isConnected: Bool
    @Environment(\.dismiss) var dismiss
    @State private var apiKey = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("API Configuration") {
                    SecureField("API Key", text: $apiKey)
                }
                
                Section {
                    Text("Enter your HubSpot API key to sync contacts, leads, and deals.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("HubSpot Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Connect") { connect() }
                        .disabled(apiKey.isEmpty)
                }
            }
        }
    }
    
    private func connect() {
        // Connect logic
        isConnected = true
        dismiss()
    }
}

// MARK: - Data Settings View
struct DataSettingsView: View {
    @State private var autoSync = true
    @State private var syncFrequency = "hourly"
    @State private var lastSyncDate: Date?
    @State private var isSyncing = false
    
    let frequencies = ["realtime", "hourly", "daily", "manual"]
    
    var body: some View {
        Form {
            Section("Sync Settings") {
                Toggle("Auto Sync", isOn: $autoSync)
                
                if autoSync {
                    Picker("Sync Frequency", selection: $syncFrequency) {
                        ForEach(frequencies, id: \.self) { f in
                            Text(f.capitalized)
                        }
                    }
                }
            }
            
            Section("Manual Sync") {
                Button(action: syncNow) {
                    HStack {
                        if isSyncing {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text(isSyncing ? "Syncing..." : "Sync Now")
                    }
                }
                .disabled(isSyncing)
                
                if let lastSync = lastSyncDate {
                    Text("Last synced: \(formatDate(lastSync))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Data Management") {
                NavigationLink("Export Data") {
                    ExportDataView()
                }
                NavigationLink("Import Data") {
                    ImportDataView()
                }
            }
            
            Section("Danger Zone") {
                Button("Clear Cache") {
                    clearCache()
                }
                .foregroundColor(.orange)
                
                Button("Reset All Data") {
                    // Show confirmation
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Data & Sync")
    }
    
    private func syncNow() {
        isSyncing = true
        // Perform sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSyncing = false
            lastSyncDate = Date()
        }
    }
    
    private func clearCache() {
        // Clear cache logic
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @State private var exportLeads = true
    @State private var exportClients = true
    @State private var exportProperties = true
    @State private var exportProjects = true
    @State private var exportTasks = true
    @State private var exportFormat = "csv"
    
    let formats = ["csv", "json", "xlsx"]
    
    var body: some View {
        Form {
            Section("Select Data") {
                Toggle("Leads", isOn: $exportLeads)
                Toggle("Clients", isOn: $exportClients)
                Toggle("Properties", isOn: $exportProperties)
                Toggle("Projects", isOn: $exportProjects)
                Toggle("Tasks", isOn: $exportTasks)
            }
            
            Section("Format") {
                Picker("Export Format", selection: $exportFormat) {
                    ForEach(formats, id: \.self) { f in
                        Text(f.uppercased())
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Button("Export") {
                    exportData()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Export Data")
    }
    
    private func exportData() {
        // Export logic
    }
}

// MARK: - Import Data View
struct ImportDataView: View {
    @State private var selectedFile: URL?
    @State private var importType = "leads"
    
    let importTypes = ["leads", "clients", "properties", "tasks"]
    
    var body: some View {
        Form {
            Section("Import Type") {
                Picker("Data Type", selection: $importType) {
                    ForEach(importTypes, id: \.self) { t in
                        Text(t.capitalized)
                    }
                }
            }
            
            Section("File") {
                Button("Select File") {
                    // File picker
                }
                
                if let file = selectedFile {
                    Text(file.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section {
                Text("Supported formats: CSV, JSON")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                Button("Import") {
                    importData()
                }
                .disabled(selectedFile == nil)
            }
        }
        .navigationTitle("Import Data")
    }
    
    private func importData() {
        // Import logic
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        Form {
            Section("App Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Links") {
                Link("Website", destination: URL(string: "https://keystonevale.org")!)
                Link("Privacy Policy", destination: URL(string: "https://keystonevale.org/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://keystonevale.org/terms")!)
            }
            
            Section("Support") {
                Link("Contact Support", destination: URL(string: "mailto:support@keystonevale.org")!)
                Link("Report a Bug", destination: URL(string: "https://keystonevale.org/feedback")!)
            }
            
            Section {
                VStack(spacing: 8) {
                    Text("Keystone Vale Holdings")
                        .font(.headline)
                    Text("© 2024 All rights reserved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .navigationTitle("About")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager(networkService: NetworkService.shared))
}
