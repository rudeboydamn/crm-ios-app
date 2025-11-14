import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var leadViewModel: LeadViewModel
    @StateObject private var propertyViewModel: PropertyViewModel
    @StateObject private var projectViewModel: RehabProjectViewModel
    
    init() {
        let networkService = NetworkService.shared
        _leadViewModel = StateObject(wrappedValue: LeadViewModel(networkService: networkService))
        _propertyViewModel = StateObject(wrappedValue: PropertyViewModel(networkService: networkService))
        _projectViewModel = StateObject(wrappedValue: RehabProjectViewModel(networkService: networkService))
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.bar.fill")
                        }
                    
                    LeadsListView()
                        .environmentObject(leadViewModel)
                        .tabItem {
                            Label("Leads", systemImage: "person.2.fill")
                        }
                    
                    PortfolioView()
                        .environmentObject(propertyViewModel)
                        .tabItem {
                            Label("Portfolio", systemImage: "building.2.fill")
                        }
                    
                    ProjectsListView()
                        .environmentObject(projectViewModel)
                        .tabItem {
                            Label("Projects", systemImage: "hammer.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .accentColor(.blue)
            } else {
                LoginView()
            }
        }
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
                        Text("Hello, \(user.fullName ?? user.email)")
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

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    if let user = authManager.currentUser {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                        
                        if let name = user.fullName {
                            HStack {
                                Text("Name")
                                Spacer()
                                Text(name)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppConfig.appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Domain")
                        Spacer()
                        Text(AppConfig.domain)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
