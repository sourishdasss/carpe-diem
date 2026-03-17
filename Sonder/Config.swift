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
}
