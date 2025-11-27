import SwiftUI

struct EnhancedPortfolioView: View {
    @EnvironmentObject var portfolioViewModel: PortfolioViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("", selection: $selectedTab) {
                    Text("Dashboard").tag(0)
                    Text("Properties").tag(1)
                    Text("Residents").tag(2)
                    Text("Payments").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                if portfolioViewModel.isLoading {
                    Spacer()
                    ProgressView("Loading portfolio data...")
                    Spacer()
                } else if let error = portfolioViewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            portfolioViewModel.fetchPortfolioData()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    Spacer()
                } else {
                    TabView(selection: $selectedTab) {
                        DashboardTabView(viewModel: portfolioViewModel)
                            .tag(0)
                        
                        PropertiesTabView(viewModel: portfolioViewModel)
                            .tag(1)
                        
                        ResidentsTabView(viewModel: portfolioViewModel)
                            .tag(2)
                        
                        PaymentsTabView(viewModel: portfolioViewModel)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Portfolio Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { portfolioViewModel.fetchPortfolioData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if portfolioViewModel.properties.isEmpty {
                    portfolioViewModel.fetchPortfolioData()
                }
            }
        }
    }
}

// MARK: - Dashboard Tab
struct DashboardTabView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let metrics = viewModel.dashboardMetrics {
                    // Primary Metrics
                    VStack(spacing: 12) {
                        MetricRow(
                            title: "Total Rent Due",
                            value: PortfolioFormatters.currency(metrics.totalRentDue),
                            icon: "dollarsign.circle.fill",
                            color: .blue
                        )
                        
                        MetricRow(
                            title: "Total Collected",
                            value: PortfolioFormatters.currency(metrics.totalRentCollected),
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        let collectionRate = metrics.collectionRate ?? 0
                        MetricRow(
                            title: "Collection Rate",
                            value: PortfolioFormatters.percent(collectionRate),
                            icon: "chart.line.uptrend.xyaxis",
                            color: collectionRate >= 90 ? .green : .orange
                        )
                        
                        Divider()
                        
                        let occupancyRate = metrics.occupancyRate ?? 0
                        MetricRow(
                            title: "Occupancy Rate",
                            value: PortfolioFormatters.percent(occupancyRate),
                            icon: "house.fill",
                            color: occupancyRate >= 90 ? .green : .orange
                        )
                        
                        let occupiedUnits = metrics.occupiedUnits ?? 0
                        let totalUnits = metrics.totalUnits ?? 0
                        MetricRow(
                            title: "Occupied Units",
                            value: "\(occupiedUnits) / \(totalUnits)",
                            icon: "person.3.fill",
                            color: .purple
                        )
                        
                        Divider()
                        
                        MetricRow(
                            title: "Portfolio Value",
                            value: PortfolioFormatters.currency(metrics.totalPortfolioValue, decimals: 0),
                            icon: "building.2.fill",
                            color: .indigo
                        )
                        
                        MetricRow(
                            title: "Monthly Income",
                            value: PortfolioFormatters.currency(metrics.totalMonthlyIncome),
                            icon: "arrow.up.circle.fill",
                            color: .green
                        )
                        
                        MetricRow(
                            title: "Monthly Expenses",
                            value: PortfolioFormatters.currency(metrics.totalMonthlyExpenses),
                            icon: "arrow.down.circle.fill",
                            color: .red
                        )
                        
                        let netCashFlow = metrics.netMonthlyCashFlow ?? 0
                        MetricRow(
                            title: "Net Cash Flow",
                            value: PortfolioFormatters.currency(netCashFlow),
                            icon: "chart.bar.fill",
                            color: netCashFlow >= 0 ? .green : .red
                        )
                    }
                    .padding()
                } else {
                    Text("No dashboard data available")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Properties Tab
struct PropertiesTabView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    
    var body: some View {
        List {
            if viewModel.properties.isEmpty {
                Text("No properties found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.properties, id: \.id) { property in
                    PropertyRow(property: property)
                }
            }
        }
    }
}

struct PropertyRow: View {
    let property: Property
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(property.address ?? "Unknown Address")
                .font(.headline)
            
            HStack {
                Text("\(property.city ?? ""), \(property.state ?? "") \(property.zip ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let units = property.totalUnits {
                    Text("\(units) units")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                if let value = property.marketValue {
                    Label("$\(value, specifier: "%.0f")", systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if let rent = property.monthlyRent {
                    Label("$\(rent, specifier: "%.0f")/mo", systemImage: "arrow.up")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Residents Tab
struct ResidentsTabView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    
    var body: some View {
        List {
            if viewModel.residents.isEmpty {
                Text("No residents found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.residents, id: \.id) { resident in
                    ResidentRow(resident: resident)
                }
            }
        }
    }
}

struct ResidentRow: View {
    let resident: Resident
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(PortfolioFormatters.residentName(first: resident.firstName, last: resident.lastName))
                .font(.headline)
            
            if let email = resident.email {
                Label(email, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let phone = resident.phone {
                Label(phone, systemImage: "phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                let statusText = (resident.status ?? "Unknown").capitalized
                let statusIsActive = resident.status?.lowercased() == "active"
                Text(statusText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusIsActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                if let moveInDate = resident.moveInDate {
                    Text("Moved in: \(moveInDate.prefix(10))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Payments Tab
struct PaymentsTabView: View {
    @ObservedObject var viewModel: PortfolioViewModel
    
    var body: some View {
        List {
            if viewModel.currentMonthPayments.isEmpty {
                Text("No payments found for current month")
                    .foregroundColor(.secondary)
            } else {
                Section("Paid (\(viewModel.paidPayments.count))") {
                    ForEach(viewModel.paidPayments, id: \.id) { payment in
                        PaymentRow(payment: payment)
                    }
                }
                
                Section("Unpaid (\(viewModel.unpaidPayments.count))") {
                    ForEach(viewModel.unpaidPayments, id: \.id) { payment in
                        PaymentRow(payment: payment)
                    }
                }
            }
        }
    }
}

struct PaymentRow: View {
    let payment: Payment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Due: \(PortfolioFormatters.date(payment.dueDate))")
                    .font(.headline)
                
                Spacer()
                
                let statusRaw = payment.status?.lowercased() ?? "pending"
                Text(statusRaw.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusRaw == "paid" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("Amount Due: \(PortfolioFormatters.currency(payment.amountDue))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let paid = payment.amountPaid {
                    Text("Paid: \(PortfolioFormatters.currency(paid))")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            if payment.paymentDate != nil || payment.paymentMethod != nil {
                HStack {
                    Text("Paid on: \(PortfolioFormatters.date(payment.paymentDate))")
                    Text("•")
                    Text("Method: \(payment.paymentMethod ?? "Unknown")")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helper Views
struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
}

// MARK: - Formatting Helpers
enum PortfolioFormatters {
    static func currency(_ value: Double?, decimals: Int = 2) -> String {
        guard let value = value else { return "$--" }
        return String(format: "$%.\(decimals)f", value)
    }
    
    static func currency(_ value: Double, decimals: Int = 2) -> String {
        return String(format: "$%.\(decimals)f", value)
    }
    
    static func percent(_ value: Double?, decimals: Int = 1) -> String {
        guard let value = value else { return "--%" }
        return String(format: "%.\(decimals)f%%", value)
    }
    
    static func percent(_ value: Double, decimals: Int = 1) -> String {
        return String(format: "%.\(decimals)f%%", value)
    }
    
    static func date(_ isoString: String?) -> String {
        guard let isoString = isoString else { return "--" }
        return String(isoString.prefix(10))
    }
    
    static func residentName(first: String?, last: String?) -> String {
        let components = [first, last].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return components.isEmpty ? "Unknown Resident" : components.joined(separator: " ")
    }
}
