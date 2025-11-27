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
                            value: "$\(viewModel.totalPortfolioValue, default: "%.0f")",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        PortfolioMetricCard(
                            title: "Monthly Income",
                            value: "$\(viewModel.totalMonthlyIncome, default: "%.0f")",
                            icon: "arrow.up.circle.fill",
                            color: .blue
                        )
                        
                        PortfolioMetricCard(
                            title: "Net Cash Flow",
                            value: "$\(viewModel.netMonthlyCashFlow, default: "%.0f")",
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            color: .purple
                        )
                        
                        PortfolioMetricCard(
                            title: "Avg ROI",
                            value: "\(viewModel.averageROI, default: "%.1f")%",
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
                Text(property.address ?? "Unknown Address")
                    .font(.headline)
                Spacer()
                PropertyStatusBadge(status: property.status)
            }
            
            Text("\(property.city ?? ""), \(property.state ?? "") \(property.zip ?? "")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                if let value = property.marketValue {
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
    let status: String?
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        guard let status = status?.lowercased() else { return .gray }
        if status.contains("owned") { return .green }
        if status.contains("sale") { return .blue }
        if status.contains("contract") { return .orange }
        if status.contains("rehab") { return .purple }
        if status.contains("rental") { return .indigo }
        return .gray
    }
    
    private var statusText: String {
        status?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown"
    }
}

struct AddPropertyView: View {
    @EnvironmentObject var viewModel: PropertyViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var propertyType: String = PropertyType.singleFamily.rawValue
    @State private var status: String = PropertyStatus.owned.rawValue
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
                                .tag(type.rawValue)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        ForEach(PropertyStatus.allCases, id: \.self) { statusCase in
                            Text(statusCase.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(statusCase.rawValue)
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
            id: UUID().uuidString,
            address: address,
            city: city,
            state: state,
            zipCode: zip,
            propertyType: propertyType,
            status: status,
            purchasePrice: Double(purchasePrice),
            marketValue: Double(currentValue),
            totalUnits: 1,
            propertyTaxAnnual: nil,
            insuranceAnnual: nil,
            hoaMonthly: nil,
            createdAt: nil
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
                    DetailRow(label: "Address", value: property.address ?? "--")
                    DetailRow(label: "City", value: property.city ?? "--")
                    DetailRow(label: "State", value: property.state ?? "--")
                    DetailRow(label: "ZIP", value: property.zip ?? "--")
                }
                
                Section(header: Text("Property Details")) {
                    DetailRow(label: "Type", value: (property.propertyType ?? "").replacingOccurrences(of: "_", with: " ").capitalized)
                    HStack {
                        Text("Status")
                            .foregroundColor(.secondary)
                        Spacer()
                        PropertyStatusBadge(status: property.status)
                    }
                }
                
                Section(header: Text("Financial")) {
                    if let purchase = property.purchasePrice {
                        DetailRow(label: "Purchase Price", value: String(format: "$%.0f", purchase))
                    }
                    if let value = property.marketValue {
                        DetailRow(label: "Market Value", value: String(format: "$%.0f", value))
                    }
                }
                
                Section(header: Text("Metrics")) {
                    DetailRow(label: "Monthly Cash Flow", value: String(format: "$%.0f", property.monthlyCashFlow))
                    DetailRow(label: "Annual Cash Flow", value: String(format: "$%.0f", property.annualCashFlow))
                    DetailRow(label: "ROI", value: String(format: "%.2f%%", property.roi))
                }
            }
            .navigationTitle("Property Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
