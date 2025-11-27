import SwiftUI

// MARK: - Portfolio Manager Main View
struct PortfolioManagerView: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    @State private var selectedTab: PortfolioTab = .dashboard
    @State private var showingMenu = false
    
    enum PortfolioTab: String, CaseIterable {
        case dashboard = "Dashboard"
        case properties = "Properties"
        case residents = "Residents"
        case recentPayments = "Recent Payments"
        case pastPayments = "Past Payments"
        case pastProperties = "Past Properties"
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.pie.fill"
            case .properties: return "building.2.fill"
            case .residents: return "person.2.fill"
            case .recentPayments: return "creditcard.fill"
            case .pastPayments: return "clock.arrow.circlepath"
            case .pastProperties: return "building.2"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .dashboard:
                        PortfolioDashboardView()
                    case .properties:
                        PropertiesListView()
                    case .residents:
                        ResidentsListView()
                    case .recentPayments:
                        PaymentsListView(showPastOnly: false)
                    case .pastPayments:
                        PaymentsListView(showPastOnly: true)
                    case .pastProperties:
                        PastPropertiesListView()
                    }
                }
                .environmentObject(viewModel)
            }
            .navigationTitle(selectedTab.rawValue)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        ForEach(PortfolioTab.allCases, id: \.self) { tab in
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
                    Button(action: { viewModel.fetchPortfolioData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if viewModel.properties.isEmpty {
                viewModel.fetchPortfolioData()
            }
        }
    }
}

// MARK: - Portfolio Dashboard
struct PortfolioDashboardView: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Key Metrics
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(
                        title: "Total Properties",
                        value: "\(viewModel.properties.count)",
                        icon: "building.2.fill",
                        color: .blue
                    )
                    MetricCard(
                        title: "Total Units",
                        value: "\(viewModel.totalUnits)",
                        icon: "door.left.hand.open",
                        color: .green
                    )
                    MetricCard(
                        title: "Occupancy Rate",
                        value: "\(Int(viewModel.occupancyRate))%",
                        icon: "chart.pie.fill",
                        color: .orange
                    )
                    MetricCard(
                        title: "Monthly Revenue",
                        value: formatCurrency(viewModel.totalMonthlyRent),
                        icon: "dollarsign.circle.fill",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // Portfolio Value Chart Placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text("Portfolio Value")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Text(formatCurrency(viewModel.totalPortfolioValue))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("Total Portfolio Value")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .padding(.horizontal)
                }
                
                // Financial Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Financial Summary")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        FinancialRow(label: "Monthly Rent Collected", value: viewModel.totalMonthlyRent, isPositive: true)
                        FinancialRow(label: "Monthly Expenses", value: viewModel.totalExpenses, isPositive: false)
                        Divider()
                        FinancialRow(label: "Net Cash Flow", value: viewModel.netCashFlow, isPositive: viewModel.netCashFlow >= 0)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Payments")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.payments.isEmpty {
                        EmptyStateView(
                            icon: "creditcard",
                            title: "No Payments",
                            message: "Recent payments will appear here"
                        )
                        .padding()
                    } else {
                        ForEach(viewModel.payments.prefix(5)) { payment in
                            PaymentRowView(payment: payment)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            viewModel.fetchPortfolioData()
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Metric Card
struct MetricCard: View {
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Financial Row
struct FinancialRow: View {
    let label: String
    let value: Double
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatCurrency(value))
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .green : .red)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(value))) ?? "$0"
    }
}

// MARK: - Properties List View
struct PropertiesListView: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    @State private var showingAddProperty = false
    @State private var searchText = ""
    
    var filteredProperties: [Property] {
        if searchText.isEmpty {
            return viewModel.properties
        }
        return viewModel.properties.filter { property in
            (property.address ?? "").localizedCaseInsensitiveContains(searchText) ||
            (property.city ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            SearchBar(text: $searchText, placeholder: "Search properties...")
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredProperties.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "No Properties",
                    message: "Tap + to add your first property"
                )
            } else {
                List {
                    ForEach(filteredProperties) { property in
                        NavigationLink(destination: PropertyDetailViewFull(property: property)) {
                            PropertyRowFull(property: property)
                        }
                    }
                    .onDelete(perform: deleteProperties)
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddProperty = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProperty) {
            AddPropertySheet()
                .environmentObject(viewModel)
        }
    }
    
    private func deleteProperties(at offsets: IndexSet) {
        for index in offsets {
            let property = filteredProperties[index]
            viewModel.deleteProperty(id: property.id)
        }
    }
}

// MARK: - Property Row Full
struct PropertyRowFull: View {
    let property: Property
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(property.address ?? "Unknown Address")
                    .font(.headline)
                Spacer()
                StatusPill(status: property.status ?? "unknown")
            }
            
            Text("\(property.city ?? ""), \(property.state ?? "") \(property.zipCode ?? "")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(formatCurrency(property.marketValue ?? 0), systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                if let units = property.totalUnits {
                    Label("\(units) units", systemImage: "door.left.hand.open")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    let status: String
    
    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "owned", "active": return .green
        case "for_sale", "for sale": return .orange
        case "under_contract", "under contract": return .blue
        case "rehabbing": return .purple
        case "rental": return .cyan
        default: return .gray
        }
    }
}

// MARK: - Residents List View
struct ResidentsListView: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    @State private var showingAddResident = false
    @State private var searchText = ""
    
    var filteredResidents: [Resident] {
        if searchText.isEmpty {
            return viewModel.residents
        }
        return viewModel.residents.filter { resident in
            resident.fullName.localizedCaseInsensitiveContains(searchText) ||
            (resident.email ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, placeholder: "Search residents...")
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredResidents.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Residents",
                    message: "Tap + to add a resident"
                )
            } else {
                List {
                    ForEach(filteredResidents) { resident in
                        NavigationLink(destination: ResidentDetailView(resident: resident)) {
                            ResidentRowView(resident: resident)
                        }
                    }
                    .onDelete(perform: deleteResidents)
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddResident = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddResident) {
            AddResidentSheet()
                .environmentObject(viewModel)
        }
    }
    
    private func deleteResidents(at offsets: IndexSet) {
        // Handle resident deletion
    }
}

// MARK: - Resident Row View
struct ResidentRowView: View {
    let resident: Resident
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(resident.initials)
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(resident.fullName)
                    .font(.headline)
                
                if let email = resident.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            StatusPill(status: resident.status ?? "active")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Payments List View
struct PaymentsListView: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    let showPastOnly: Bool
    @State private var showingAddPayment = false
    
    var displayedPayments: [Payment] {
        if showPastOnly {
            return viewModel.payments.filter { $0.isPast }
        }
        return viewModel.payments.filter { !$0.isPast }
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayedPayments.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: showPastOnly ? "No Past Payments" : "No Recent Payments",
                    message: showPastOnly ? "Past payments will appear here" : "Tap + to record a payment"
                )
            } else {
                List {
                    ForEach(displayedPayments) { payment in
                        PaymentRowView(payment: payment)
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            if !showPastOnly {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPayment = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentSheet()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Payment Row View
struct PaymentRowView: View {
    let payment: Payment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.residentName ?? "Unknown Resident")
                    .font(.headline)
                Text(formatDateString(payment.paymentDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(payment.amount))
                    .font(.headline)
                    .foregroundColor(.green)
                StatusPill(status: payment.status ?? "completed")
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatDateString(_ dateStr: String?) -> String {
        guard let dateStr = dateStr,
              let date = ISO8601DateFormatter().date(from: dateStr) else { return "--" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Past Properties List View
struct PastPropertiesListView: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    
    var pastProperties: [Property] {
        viewModel.properties.filter { ($0.status ?? "").lowercased() == "sold" }
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pastProperties.isEmpty {
                EmptyStateView(
                    icon: "building.2",
                    title: "No Past Properties",
                    message: "Sold properties will appear here"
                )
            } else {
                List {
                    ForEach(pastProperties) { property in
                        PropertyRowFull(property: property)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Add Property Sheet
struct AddPropertySheet: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var propertyType = "single_family"
    @State private var status = "owned"
    @State private var purchasePrice = ""
    @State private var marketValue = ""
    @State private var totalUnits = "1"
    
    let propertyTypes = ["single_family", "multi_family", "condo", "townhouse", "commercial"]
    let statuses = ["owned", "for_sale", "under_contract", "rehabbing", "rental"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Location") {
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                }
                
                Section("Property Details") {
                    Picker("Type", selection: $propertyType) {
                        ForEach(propertyTypes, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.self) { s in
                            Text(s.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                    
                    TextField("Total Units", text: $totalUnits)
                        .keyboardType(.numberPad)
                }
                
                Section("Financial") {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Market Value", text: $marketValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProperty() }
                        .disabled(address.isEmpty || city.isEmpty)
                }
            }
        }
    }
    
    private func saveProperty() {
        let property = Property(
            id: UUID().uuidString,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            propertyType: propertyType,
            status: status,
            purchasePrice: Double(purchasePrice),
            marketValue: Double(marketValue),
            totalUnits: Int(totalUnits),
            propertyTaxAnnual: nil,
            insuranceAnnual: nil,
            hoaMonthly: nil,
            createdAt: nil
        )
        viewModel.createProperty(property)
        dismiss()
    }
}

// MARK: - Add Resident Sheet
struct AddResidentSheet: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var moveInDate = Date()
    
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
                
                Section("Lease Details") {
                    DatePicker("Move-in Date", selection: $moveInDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Resident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveResident() }
                        .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }
    
    private func saveResident() {
        // Save resident logic
        dismiss()
    }
}

// MARK: - Add Payment Sheet
struct AddPaymentSheet: View {
    @EnvironmentObject var viewModel: PortfolioViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var amount = ""
    @State private var paymentDate = Date()
    @State private var selectedResident: Resident?
    @State private var paymentType = "rent"
    @State private var notes = ""
    
    let paymentTypes = ["rent", "deposit", "late_fee", "other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Payment Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                    
                    Picker("Payment Type", selection: $paymentType) {
                        ForEach(paymentTypes, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes)
                }
            }
            .navigationTitle("Record Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { savePayment() }
                        .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func savePayment() {
        // Save payment logic
        dismiss()
    }
}

// MARK: - Property Detail View Full
struct PropertyDetailViewFull: View {
    let property: Property
    @State private var showingEdit = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 12) {
                    Text(property.address ?? "Unknown Address")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(property.city ?? ""), \(property.state ?? "") \(property.zipCode ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    StatusPill(status: property.status ?? "unknown")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Financial Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("Financial Details")
                        .font(.headline)
                    
                    DetailRowView(label: "Purchase Price", value: formatCurrency(property.purchasePrice ?? 0))
                    DetailRowView(label: "Market Value", value: formatCurrency(property.marketValue ?? 0))
                    DetailRowView(label: "Property Type", value: (property.propertyType ?? "").replacingOccurrences(of: "_", with: " ").capitalized)
                    DetailRowView(label: "Total Units", value: "\(property.totalUnits ?? 0)")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditPropertySheet(property: property)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Detail Row View
struct DetailRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Resident Detail View
struct ResidentDetailView: View {
    let resident: Resident
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(resident.initials)
                                .font(.title)
                                .foregroundColor(.blue)
                        )
                    
                    Text(resident.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    StatusPill(status: resident.status ?? "active")
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
                    
                    if let email = resident.email {
                        DetailRowView(label: "Email", value: email)
                    }
                    if let phone = resident.phone {
                        DetailRowView(label: "Phone", value: phone)
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Edit Property Sheet
struct EditPropertySheet: View {
    let property: Property
    @Environment(\.dismiss) var dismiss
    
    @State private var address: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var propertyType: String
    @State private var status: String
    @State private var purchasePrice: String
    @State private var marketValue: String
    
    init(property: Property) {
        self.property = property
        _address = State(initialValue: property.address ?? "")
        _city = State(initialValue: property.city ?? "")
        _state = State(initialValue: property.state ?? "")
        _zipCode = State(initialValue: property.zipCode ?? "")
        _propertyType = State(initialValue: property.propertyType ?? "single_family")
        _status = State(initialValue: property.status ?? "owned")
        _purchasePrice = State(initialValue: property.purchasePrice.map { String($0) } ?? "")
        _marketValue = State(initialValue: property.marketValue.map { String($0) } ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Location") {
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zipCode)
                }
                
                Section("Details") {
                    TextField("Property Type", text: $propertyType)
                    TextField("Status", text: $status)
                }
                
                Section("Financial") {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Market Value", text: $marketValue)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Edit Property")
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
        // Save changes logic
        dismiss()
    }
}

#Preview {
    PortfolioManagerView()
        .environmentObject(PortfolioViewModel())
}
