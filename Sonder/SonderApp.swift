import SwiftUI

@main
struct SonderApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var auth = AuthStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isSignedIn {
                    ContentRootView()
                        .environmentObject(store)
                        .environmentObject(auth)
                } else {
                    AuthScreen()
                        .environmentObject(auth)
                }
            }
            .onAppear {
                store.setAIBackend(goBaseURL: Config.goAIBaseURL)
                store.configureSupabase(url: Config.supabaseURL, anonKey: Config.supabaseAnonKey)
                Task {
                    await auth.refresh()
                    if auth.isSignedIn {
                        await store.loadFromSupabase()
                    }
                }
            }
            .onChange(of: auth.isSignedIn) { signedIn in
                if signedIn {
                    Task { await store.loadFromSupabase() }
                } else {
                    store.resetForSignedOut()
                }
            }
        }
    }
}
