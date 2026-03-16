import SwiftUI

@main
struct SonderApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(store)
                .onAppear {
                    if ProcessInfo.processInfo.environment["CLAUDE_API_KEY"] != nil {
                        store.setAPIKey(ProcessInfo.processInfo.environment["CLAUDE_API_KEY"]!)
                    }
                    store.seedDemoCities()
                }
        }
    }
}
