import SwiftUI

@main
struct SonderApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environmentObject(store)
                .onAppear {
                    if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
                        store.setAPIKey(key)
                    }
                    store.configureSupabase(url: Config.supabaseURL, anonKey: Config.supabaseAnonKey)
                    Task { await store.loadFromSupabase() }
                }
        }
    }
}
