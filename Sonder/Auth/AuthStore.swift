import Foundation
import SwiftUI

@MainActor
final class AuthStore: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    func refresh() async {
        isSignedIn = await supabase.isSignedIn()
    }

    func signUp(firstName: String, lastName: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.signUp(email: email, password: password)
            isSignedIn = await supabase.isSignedIn()
            if isSignedIn {
                do {
                    try await supabase.upsertProfile(firstName: firstName, lastName: lastName)
                } catch {
                    // Account exists but profile row failed (often schema/RLS mismatch).
                    errorMessage = "Signed up, but saving your profile failed: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.signIn(email: email, password: password)
            isSignedIn = await supabase.isSignedIn()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.signOut()
            isSignedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

