import SwiftUI

@available(iOS 16.0, *)
@main
struct CRMApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
