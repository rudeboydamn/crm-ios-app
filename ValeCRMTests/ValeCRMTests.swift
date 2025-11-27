//
//  ValeCRMTests.swift
//  ValeCRMTests
//
//  Created by Dammy Henry on 11/14/25.
//

import Testing
@testable import ValeCRM
import Combine
import Foundation

struct ValeCRMTests {

    @Test func testNetworkServiceConfiguration() async throws {
        _ = NetworkService.shared
        // Verify API configuration matches website backend
        #expect(AppConfig.apiBaseURL.hasPrefix("https://"))
        #expect(AppConfig.apiURL.absoluteString == AppConfig.apiBaseURL)
        #expect(!AppConfig.adminUserId.isEmpty)
    }

    @Test func testAuthManagerInitialization() async throws {
        let networkService = NetworkService.shared
        let authManager = AuthManager(networkService: networkService)
        // Should start unauthenticated
        #expect(!authManager.isAuthenticated)
        #expect(authManager.currentUser == nil)
    }

    @Test func testLeadModelEncoding() throws {
        let lead = Lead(
            id: UUID().uuidString,
            createdAt: Date(),
            updatedAt: Date(),
            hubspotId: nil,
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            phone: "555-1234",
            source: .webForm,
            status: .new,
            priority: .warm,
            tags: [],
            propertyAddress: "123 Main St",
            propertyCity: "Anytown",
            propertyState: "CA",
            propertyZip: "12345",
            askingPrice: 250000.0,
            offerAmount: nil,
            arv: nil
        )
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(lead)
        #expect(!data.isEmpty)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(Lead.self, from: data)
        #expect(decoded.id == lead.id)
        #expect(decoded.email == lead.email)
    }

    @Test func testPropertyModel() throws {
        let property = Property(
            id: UUID().uuidString,
            address: "456 Oak Ave",
            city: "Springfield",
            state: "IL",
            zipCode: "62701",
            propertyType: PropertyType.singleFamily.rawValue,
            status: PropertyStatus.owned.rawValue,
            purchasePrice: 300000.0,
            marketValue: 350000.0,
            totalUnits: 1,
            propertyTaxAnnual: nil,
            insuranceAnnual: nil,
            hoaMonthly: nil,
            createdAt: nil
        )
        
        #expect(property.zip == "62701")
        #expect(property.currentValue == 350000.0)
    }

    @Test func testRehabProjectBudgetCalculations() throws {
        let project = RehabProject()
        
        #expect(project.remainingBudget == 37500.0)
        #expect(project.budgetUtilization == 25.0)
    }

}
