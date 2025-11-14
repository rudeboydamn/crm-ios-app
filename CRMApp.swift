import SwiftUI

@main
struct CRMApp: App {
    @StateObject private var authManager = AuthManager(networkService: NetworkService())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
