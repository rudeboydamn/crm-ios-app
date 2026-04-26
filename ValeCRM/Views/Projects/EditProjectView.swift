import SwiftUI

struct EditProjectView: View {
    let project: RehabProject
    @EnvironmentObject var viewModel: RehabProjectViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var propertyName: String
    @State private var propertyAddress: String
    @State private var status: String
    @State private var measuredSqft: String
    @State private var rehabType: String
    @State private var purchaseDate: Date
    @State private var sellDate: Date?
    
    // Purchase Costs
    @State private var propertyPurchase: String
    @State private var homeInspection: String
    @State private var appraisal: String
    @State private var survey: String
    @State private var lenderFees: String
    @State private var purchaseClosingCosts: String
    @State private var purchaseOther: String
    
    // Rehab Costs
    @State private var totalContractor: String
    @State private var totalMaterials: String
    
    // Holding Costs
    @State private var mortgageInterest: String
    @State private var investorMortgageInterest: String
    @State private var propertyTaxes: String
    @State private var insurance: String
    @State private var totalUtilities: String
    @State private var lawnCare: String
    @State private var holdingOther: String
    
    // Selling Costs
    @State private var salesRevenue: String
    @State private var brokerCommissionPercent: String
    @State private var homeWarranty: String
    @State private var buyerTermite: String
    @State private var closingCostsBuyer: String
    @State private var sellingClosingCosts: String
    
    init(project: RehabProject) {
        self.project = project
        _propertyName = State(initialValue: project.propertyName)
        _propertyAddress = State(initialValue: project.propertyAddress)
        _status = State(initialValue: project.status.rawValue)
        _measuredSqft = State(initialValue: project.measuredSqft != nil ? "\(project.measuredSqft!)" : "")
        _rehabType = State(initialValue: project.rehabType ?? "")
        _purchaseDate = State(initialValue: project.startDate ?? Date())
        _sellDate = State(initialValue: project.completionDate)
        
        _propertyPurchase = State(initialValue: project.propertyPurchase != nil ? "\(project.propertyPurchase!)" : "")
        _homeInspection = State(initialValue: project.homeInspection != nil ? "\(project.homeInspection!)" : "")
        _appraisal = State(initialValue: project.appraisal != nil ? "\(project.appraisal!)" : "")
        _survey = State(initialValue: project.survey != nil ? "\(project.survey!)" : "")
        _lenderFees = State(initialValue: project.lenderFees != nil ? "\(project.lenderFees!)" : "")
        _purchaseClosingCosts = State(initialValue: project.purchaseClosingCosts != nil ? "\(project.purchaseClosingCosts!)" : "")
        _purchaseOther = State(initialValue: project.purchaseOther != nil ? "\(project.purchaseOther!)" : "")
        
        _totalContractor = State(initialValue: project.totalContractor != nil ? "\(project.totalContractor!)" : "")
        _totalMaterials = State(initialValue: project.totalMaterials != nil ? "\(project.totalMaterials!)" : "")
        
        _mortgageInterest = State(initialValue: project.mortgageInterest != nil ? "\(project.mortgageInterest!)" : "")
        _investorMortgageInterest = State(initialValue: project.investorMortgageInterest != nil ? "\(project.investorMortgageInterest!)" : "")
        _propertyTaxes = State(initialValue: project.propertyTaxes != nil ? "\(project.propertyTaxes!)" : "")
        _insurance = State(initialValue: project.insurance != nil ? "\(project.insurance!)" : "")
        _totalUtilities = State(initialValue: project.totalUtilities != nil ? "\(project.totalUtilities!)" : "")
        _lawnCare = State(initialValue: project.lawnCare != nil ? "\(project.lawnCare!)" : "")
        _holdingOther = State(initialValue: project.holdingOther != nil ? "\(project.holdingOther!)" : "")
        
        _salesRevenue = State(initialValue: project.salesRevenue != nil ? "\(project.salesRevenue!)" : "")
        _brokerCommissionPercent = State(initialValue: project.brokerCommissionPercent != nil ? "\(project.brokerCommissionPercent!)" : "")
        _homeWarranty = State(initialValue: project.homeWarranty != nil ? "\(project.homeWarranty!)" : "")
        _buyerTermite = State(initialValue: project.buyerTermite != nil ? "\(project.buyerTermite!)" : "")
        _closingCostsBuyer = State(initialValue: project.closingCostsBuyer != nil ? "\(project.closingCostsBuyer!)" : "")
        _sellingClosingCosts = State(initialValue: project.sellingClosingCosts != nil ? "\(project.sellingClosingCosts!)" : "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Information")) {
                    TextField("Property Name", text: $propertyName)
                    TextField("Property Address", text: $propertyAddress)
                    
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { statusCase in
                            Text(statusCase.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(statusCase.rawValue)
                        }
                    }
                    
                    TextField("Square Footage", text: $measuredSqft)
                        .keyboardType(.decimalPad)
                    
                    TextField("Rehab Type", text: $rehabType)
                    
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    
                    if let date = sellDate {
                        DatePicker("Sell Date", selection: Binding(
                            get: { date },
                            set: { sellDate = $0 }
                        ), displayedComponents: .date)
                    } else {
                        Button("Add Sell Date") {
                            sellDate = Date()
                        }
                    }
                }
                
                Section(header: Text("Purchase Costs")) {
                    CurrencyField(label: "Property Purchase", text: $propertyPurchase)
                    CurrencyField(label: "Home Inspection", text: $homeInspection)
                    CurrencyField(label: "Appraisal", text: $appraisal)
                    CurrencyField(label: "Survey", text: $survey)
                    CurrencyField(label: "Lender Fees", text: $lenderFees)
                    CurrencyField(label: "Closing Costs", text: $purchaseClosingCosts)
                    CurrencyField(label: "Other", text: $purchaseOther)
                }
                
                Section(header: Text("Rehab Costs")) {
                    CurrencyField(label: "Contractor Costs", text: $totalContractor)
                    CurrencyField(label: "Materials", text: $totalMaterials)
                }
                
                Section(header: Text("Holding Costs")) {
                    CurrencyField(label: "Mortgage Interest", text: $mortgageInterest)
                    CurrencyField(label: "Investor Mortgage Interest", text: $investorMortgageInterest)
                    CurrencyField(label: "Property Taxes", text: $propertyTaxes)
                    CurrencyField(label: "Insurance", text: $insurance)
                    CurrencyField(label: "Utilities", text: $totalUtilities)
                    CurrencyField(label: "Lawn Care", text: $lawnCare)
                    CurrencyField(label: "Other", text: $holdingOther)
                }
                
                Section(header: Text("Selling Costs")) {
                    CurrencyField(label: "Sales Revenue", text: $salesRevenue)
                    TextField("Broker Commission %", text: $brokerCommissionPercent)
                        .keyboardType(.decimalPad)
                    CurrencyField(label: "Home Warranty", text: $homeWarranty)
                    CurrencyField(label: "Buyer Termite", text: $buyerTermite)
                    CurrencyField(label: "Closing Costs (Buyer)", text: $closingCostsBuyer)
                    CurrencyField(label: "Selling Closing Costs", text: $sellingClosingCosts)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveProject()
                }
            )
        }
    }
    
    private func saveProject() {
        var updatedProject = project
        updatedProject.propertyName = propertyName
        updatedProject.propertyAddress = propertyAddress
        updatedProject.status = ProjectStatus(rawValue: status) ?? .planning
        updatedProject.measuredSqft = Double(measuredSqft)
        updatedProject.rehabType = rehabType.isEmpty ? nil : rehabType
        updatedProject.purchaseDate = isoFormatter.string(from: purchaseDate)
        updatedProject.sellDate = sellDate != nil ? isoFormatter.string(from: sellDate!) : nil
        
        updatedProject.propertyPurchase = Double(propertyPurchase)
        updatedProject.homeInspection = Double(homeInspection)
        updatedProject.appraisal = Double(appraisal)
        updatedProject.survey = Double(survey)
        updatedProject.lenderFees = Double(lenderFees)
        updatedProject.purchaseClosingCosts = Double(purchaseClosingCosts)
        updatedProject.purchaseOther = Double(purchaseOther)
        
        updatedProject.totalContractor = Double(totalContractor)
        updatedProject.totalMaterials = Double(totalMaterials)
        
        updatedProject.mortgageInterest = Double(mortgageInterest)
        updatedProject.investorMortgageInterest = Double(investorMortgageInterest)
        updatedProject.propertyTaxes = Double(propertyTaxes)
        updatedProject.insurance = Double(insurance)
        updatedProject.totalUtilities = Double(totalUtilities)
        updatedProject.lawnCare = Double(lawnCare)
        updatedProject.holdingOther = Double(holdingOther)
        
        updatedProject.salesRevenue = Double(salesRevenue)
        updatedProject.brokerCommissionPercent = Double(brokerCommissionPercent)
        updatedProject.homeWarranty = Double(homeWarranty)
        updatedProject.buyerTermite = Double(buyerTermite)
        updatedProject.closingCostsBuyer = Double(closingCostsBuyer)
        updatedProject.sellingClosingCosts = Double(sellingClosingCosts)
        
        viewModel.updateProject(updatedProject)
        dismiss()
    }
    
    private var isoFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

struct CurrencyField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("$0.00", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
        }
    }
}
