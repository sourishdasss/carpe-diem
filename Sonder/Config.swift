import Foundation

enum Config {
    /// Supabase project URL (from Project Settings → API).
    static var supabaseURL: String {
        ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? "https://ghgyqptnsgbytmuajhvl.supabase.co"
    }

    /// Supabase anon (public) key. Safe to use in the app; RLS protects data.
    /// Never use the service_role key in client code.
    static var supabaseAnonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdoZ3lxcHRuc2dieXRtdWFqaHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM3MDQwMDQsImV4cCI6MjA4OTI4MDAwNH0.6Llmgl7a-I-ax3A2y9Y0qMeGODAe9sUNHw7pdpLq7yw"
    }

    /// Go backend base URL (used for /api/city-score and /api/travel-profile).
    /// In iOS Simulator, `localhost` typically reaches the Mac host.
    static var goAIBaseURL: String {
        ProcessInfo.processInfo.environment["GO_AI_BASE_URL"] ?? "http://127.0.0.1:8080"
    }

    /// Feature flag: when false, we compute city scores + travel profile locally.
    /// Set `AI_ENABLED=true` to turn Gemini/Go AI back on.
    static var aiEnabled: Bool {
        let raw = ProcessInfo.processInfo.environment["AI_ENABLED"] ?? "false"
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
    }

    /// Feature flag: keep the app functional without setting up feed tables/policies.
    /// Set `FEED_ENABLED=true` when you want the social feed.
    static var feedEnabled: Bool {
        let raw = ProcessInfo.processInfo.environment["FEED_ENABLED"] ?? "false"
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
    }
}
