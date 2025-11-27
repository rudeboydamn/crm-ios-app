import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        MainTabView()
            .environmentObject(authManager)
    }
}

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Welcome to ValeCRM")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    if let user = authManager.currentUser {
                        let displayName = user.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        Text("Hello, \(displayName.isEmpty ? user.email : displayName)")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick stats would go here
                    VStack(spacing: 15) {
                        DashboardCard(title: "Active Leads", value: "0", icon: "person.2.fill", color: .blue)
                        DashboardCard(title: "Properties", value: "0", icon: "building.2.fill", color: .green)
                        DashboardCard(title: "Active Projects", value: "0", icon: "hammer.fill", color: .orange)
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// More View with additional features and settings
struct MoreView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var leadViewModel: LeadViewModel
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                List {
                    Section("Sales & Operations") {
                        NavigationLink(destination: LeadsListView().environmentObject(leadViewModel)) {
                            Label("Leads", systemImage: "person.2.fill")
                        }
                        
                        NavigationLink(destination: ClientsListView()) {
                            Label("Clients", systemImage: "person.3.fill")
                        }
                        
                        NavigationLink(destination: CommunicationsView()) {
                            Label("Communications", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                        
                        NavigationLink(destination: DocumentsView()) {
                            Label("Documents", systemImage: "doc.fill")
                        }
                    }
                    
                    Section("Insights") {
                        NavigationLink(destination: ReportsView()) {
                            Label("Reports & Analytics", systemImage: "chart.xyaxis.line")
                        }
                    }
                    
                    Section("Account") {
                        NavigationLink(destination: ProfileView()) {
                            Label("Profile", systemImage: "person.circle.fill")
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            _Concurrency.Task {
                                await authManager.signOut()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sign Out")
                                Spacer()
                            }
                        }
                    }
                }
                .navigationTitle("More")
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Form {
            if let user = authManager.currentUser {
                Section("Account Information") {
                    HStack {
                        Text("User ID")
                        Spacer()
                        Text(user.userId)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }
                    
                    let trimmedName = user.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(trimmedName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(user.role.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Form {
            Section("App Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(AppConfig.appVersion)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Domain")
                    Spacer()
                    Text(AppConfig.websiteURL)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                HStack {
                    Text("Company")
                    Spacer()
                    Text(AppConfig.companyName)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Contact") {
                Link(destination: URL(string: "tel:\(AppConfig.phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: ""))")!) {
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(AppConfig.phoneNumber)
                            .foregroundColor(.blue)
                    }
                }
                
                Link(destination: URL(string: "mailto:\(AppConfig.supportEmail)")!) {
                    HStack {
                        Text("Support Email")
                        Spacer()
                        Text(AppConfig.supportEmail)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Placeholder views for Communications, Documents, and Reports
struct CommunicationsView: View {
    @StateObject private var viewModel = CommunicationViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading communications...")
            } else if viewModel.recentCommunications.isEmpty {
                Text("No communications yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.recentCommunications) { comm in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: comm.type.iconName)
                                .foregroundColor(.blue)
                            Text(comm.displayTitle)
                                .font(.headline)
                        }
                        Text(comm.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        Text(comm.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Communications")
        .onAppear {
            if viewModel.communications.isEmpty {
                viewModel.fetchCommunications()
            }
        }
    }
}

struct DocumentsView: View {
    var body: some View {
        List {
            Text("Document management coming soon")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Documents")
    }
}

struct ReportsView: View {
    var body: some View {
        List {
            NavigationLink(destination: Text("Leads Report")) {
                Label("Leads Overview", systemImage: "person.2.fill")
            }
            
            NavigationLink(destination: Text("Sales Pipeline")) {
                Label("Sales Pipeline", systemImage: "chart.line.uptrend.xyaxis")
            }
            
            NavigationLink(destination: Text("Projects Performance")) {
                Label("Projects Performance", systemImage: "hammer.fill")
            }
            
            NavigationLink(destination: Text("Portfolio Analysis")) {
                Label("Portfolio Analysis", systemImage: "building.2.fill")
            }
            
            NavigationLink(destination: Text("Financial Summary")) {
                Label("Financial Summary", systemImage: "dollarsign.circle.fill")
            }
        }
        .navigationTitle("Reports & Analytics")
    }
}
