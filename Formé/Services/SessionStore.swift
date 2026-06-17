//
//  SessionStore.swift
//  Formé
//
//  App-wide source of truth for the signed-in user's profile + goals.
//  Loaded from Supabase on launch (and after onboarding) so every screen
//  reads real data instead of mocks. Injected as an @EnvironmentObject from
//  Forme_App and consumed by Home, Profile, etc.
//

import SwiftUI
import Combine

@MainActor
final class SessionStore: ObservableObject {

    @Published var profile: UserProfile?
    @Published var isLoading = false

    /// Fetches the user's profile + active goal from Supabase.
    /// Safe to call repeatedly (e.g. each time the main tab view appears).
    func loadProfile(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await ProfileService.shared.fetchProfile(userId: userId)
        } catch {
            // Leave whatever we had; screens fall back to sensible defaults.
            // (Don't clobber an existing profile just because a refresh failed.)
        }
    }

    /// Clears cached profile on sign-out / account deletion.
    func clear() {
        profile = nil
    }

    // MARK: Convenience accessors with safe fallbacks

    var firstName: String {
        let name = profile?.firstName ?? ""
        return name.isEmpty ? "there" : name
    }

    var calorieGoal: Int { profile?.dailyCalorieTarget ?? 2200 }
    var proteinGoal: Int { profile?.proteinTargetG ?? 150 }
    var carbsGoal: Int   { profile?.carbsTargetG ?? 200 }
    var fatGoal: Int     { profile?.fatTargetG ?? 65 }
}
