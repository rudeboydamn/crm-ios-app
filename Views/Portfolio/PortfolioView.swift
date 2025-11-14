import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var viewModel: PropertyViewModel
    @State private var showingAddProperty = false
    @State private var selectedProperty: Property?
    
    var body: some View {
        NavigationView {
            VStack {
                // Portfolio Summary Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        PortfolioMetricCard(
                            title: "Total Value",
                            value: "$\(viewModel.totalPortfolioValue, specifier: "%.0f")",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        PortfolioMetricCard(
                            title: "Monthly Income",
                            value: "$\(viewModel.totalMonthlyIncome, specifier: "%.0f")",
                            icon: "arrow.up.circle.fill",
                            color: .blue
                        )
                        
                        PortfolioMetricCard(
                            title: "Net Cash Flow",
                            value: "$\(viewModel.netMonthlyCashFlow, specifier: "%.0f")",
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            color: .purple
                        )
                        
                        PortfolioMetricCard(
                            title: "Avg ROI",
                            value: "\(viewModel.averageROI, specifier: "%.1f")%",
                            icon: "percent.circle.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Properties List
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.properties.isEmpty {
                    EmptyStateView(
                        icon: "building.2.fill",
                        title: "No Properties Yet",
                        message: "Tap the + button to add your first property"
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredProperties) { property in
                            PropertyRowView(property: property)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedProperty = property
                                }
                        }
                    }
                }
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProperty = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.fetchProperties) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingAddProperty) {
                AddPropertyView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedProperty) { property in
                PropertyDetailView(property: property)
                    .environmentObject(viewModel)
            }
            .onAppear {
                if viewModel.properties.isEmpty {
                    viewModel.fetchProperties()
                }
            }
        }
    }
}

struct PortfolioMetricCard: View {
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

struct PropertyRowView: View {
    let property: Property
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(property.address)
                    .font(.headline)
                Spacer()
                PropertyStatusBadge(status: property.status)
            }
            
            Text("\(property.city), \(property.state) \(property.zip)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                if let value = property.currentValue {
                    VStack(alignment: .leading) {
                        Text("Value")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(value, specifier: "%.0f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("ROI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(property.roi, specifier: "%.1f")%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(property.roi > 0 ? .green : .gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PropertyStatusBadge: View {
    let status: PropertyStatus
    
    var body: some View {
        Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .owned: return .green
        case .forSale: return .blue
        case .underContract: return .orange
        case .rehabbing: return .purple
        case .rental: return .indigo
        }
    }
}

struct AddPropertyView: View {
    @EnvironmentObject var viewModel: PropertyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var propertyType: PropertyType = .singleFamily
    @State private var status: PropertyStatus = .owned
    @State private var purchasePrice = ""
    @State private var currentValue = ""
    @State private var monthlyRent = ""
    @State private var monthlyExpenses = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Location")) {
                    TextField("Address", text: $address)
                    TextField("City", text: $city)
                    TextField("State", text: $state)
                    TextField("ZIP Code", text: $zip)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Property Details")) {
                    Picker("Type", selection: $propertyType) {
                        ForEach(PropertyType.allCases, id: \.self) { type in
                            Text(type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(PropertyStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        }
                    }
                }
                
                Section(header: Text("Financial Information")) {
                    TextField("Purchase Price", text: $purchasePrice)
                        .keyboardType(.decimalPad)
                    TextField("Current Value", text: $currentValue)
                        .keyboardType(.decimalPad)
                    TextField("Monthly Rent (optional)", text: $monthlyRent)
                        .keyboardType(.decimalPad)
                    TextField("Monthly Expenses (optional)", text: $monthlyExpenses)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Property")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveProperty()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        !address.isEmpty && !city.isEmpty && !state.isEmpty && !zip.isEmpty
    }
    
    private func saveProperty() {
        let property = Property(
            id: UUID(),
            address: address,
            city: city,
            state: state,
            zip: zip,
            propertyType: propertyType,
            status: status,
            purchasePrice: Double(purchasePrice),
            currentValue: Double(currentValue),
            monthlyRent: Double(monthlyRent),
            monthlyExpenses: Double(monthlyExpenses)
        )
        
        viewModel.createProperty(property)
        presentationMode.wrappedValue.dismiss()
    }
}

struct PropertyDetailView: View {
    let property: Property
    @EnvironmentObject var viewModel: PropertyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Location")) {
                    DetailRow(label: "Address", value: property.address)
                    DetailRow(label: "City", value: property.city)
                    DetailRow(label: "State", value: property.state)
                    DetailRow(label: "ZIP", value: property.zip)
                }
                
                Section(header: Text("Property Details")) {
                    DetailRow(label: "Type", value: property.propertyType.rawValue.capitalized)
                    HStack {
                        Text("Status")
                            .foregroundColor(.secondary)
                        Spacer()
                        PropertyStatusBadge(status: property.status)
                    }
                }
                
                Section(header: Text("Financial")) {
                    if let purchase = property.purchasePrice {
                        DetailRow(label: "Purchase Price", value: "$\(purchase, specifier: "%.0f")")
                    }
                    if let value = property.currentValue {
                        DetailRow(label: "Current Value", value: "$\(value, specifier: "%.0f")")
                    }
                    if let rent = property.monthlyRent {
                        DetailRow(label: "Monthly Rent", value: "$\(rent, specifier: "%.0f")")
                    }
                    if let expenses = property.monthlyExpenses {
                        DetailRow(label: "Monthly Expenses", value: "$\(expenses, specifier: "%.0f")")
                    }
                }
                
                Section(header: Text("Metrics")) {
                    DetailRow(label: "Monthly Cash Flow", value: "$\(property.monthlyCashFlow, specifier: "%.0f")")
                    DetailRow(label: "Annual Cash Flow", value: "$\(property.annualCashFlow, specifier: "%.0f")")
                    DetailRow(label: "ROI", value: "\(property.roi, specifier: "%.2f")%")
                }
            }
            .navigationTitle("Property Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
