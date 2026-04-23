//
//  SupabaseService.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//
//  Singleton Supabase client.
//  ProfileService maps UserProfile ↔ the real DB schema:
//    - public.profiles  (identity + body stats + preferences)
//    - public.goals     (calorie/macro targets, goal type)

import Foundation
import Supabase

// MARK: - Client

final class SupabaseService {

    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://gqdaczlcxinemjelirip.supabase.co")!,
            supabaseKey: "sb_publishable_1UIZcIynAFeViksiSQML2Q_Q8wC7Cem"
        )
    }
}

// MARK: - Row Types (match actual Supabase schema)

/// Mirrors public.profiles columns used by the app.
struct ProfileRow: Codable {
    var id: UUID
    var full_name: String?
    var avatar_url: String?
    var date_of_birth: String?      // "YYYY-MM-DD"
    var gender: String?             // 'male' | 'female' | 'other' | 'prefer_not_to_say'
    var height_cm: Double?
    var weight_kg: Double?
    var activity_level: String?     // 'sedentary' | 'lightly_active' | 'moderately_active' | 'very_active' | 'extra_active'
    var units: String?              // 'metric' | 'imperial'
    var onboarding_done: Bool?
}

/// Mirrors public.goals columns used by the app.
struct GoalRow: Codable {
    var user_id: UUID
    var goal_type: String           // 'weight_loss' | 'muscle_gain' | 'maintenance' | 'custom' | 'performance'
    var target_weight_kg: Double?
    var calorie_target: Int
    var protein_target_g: Int?
    var carbs_target_g: Int?
    var fat_target_g: Int?
    var is_active: Bool
}

// MARK: - Profile Service

final class ProfileService {

    static let shared = ProfileService()
    private init() {}

    private var db: SupabaseClient { SupabaseService.shared.client }

    // MARK: Save (upsert profile + insert/update active goal)

    func saveProfile(_ profile: UserProfile) async throws {
        guard let userIdString = profile.id,
              let userId = UUID(uuidString: userIdString) else {
            throw ProfileError.missingUserId
        }

        // --- profiles row ---
        let profileRow = ProfileRow(
            id:             userId,
            full_name:      profile.fullName.isEmpty ? nil : profile.fullName,
            avatar_url:     profile.avatarURL,
            date_of_birth:  approximateBirthDate(fromAge: profile.age),
            gender:         profile.biologicalSex.rawValue,
            height_cm:      profile.heightCm,
            weight_kg:      profile.weightKg,
            activity_level: profile.activityLevel.rawValue,
            units:          profile.weightUnit == .kg ? "metric" : "imperial",
            onboarding_done: profile.hasCompletedOnboarding
        )

        try await db
            .from("profiles")
            .upsert(profileRow)
            .execute()

        // --- goals row (deactivate old, insert new active goal) ---
        try await db
            .from("goals")
            .update(["is_active": false])
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .execute()

        let goalRow = GoalRow(
            user_id:          userId,
            goal_type:        profile.goal.rawValue,
            target_weight_kg: profile.targetWeightKg,
            calorie_target:   profile.dailyCalorieTarget,
            protein_target_g: profile.proteinTargetG,
            carbs_target_g:   profile.carbsTargetG,
            fat_target_g:     profile.fatTargetG,
            is_active:        true
        )

        try await db
            .from("goals")
            .insert(goalRow)
            .execute()
    }

    // MARK: Fetch

    func fetchProfile(userId: String) async throws -> UserProfile? {
        guard let uuid = UUID(uuidString: userId) else { return nil }

        // Fetch profile row
        let profiles: [ProfileRow] = try await db
            .from("profiles")
            .select()
            .eq("id", value: uuid)
            .limit(1)
            .execute()
            .value

        guard let row = profiles.first else { return nil }

        // Fetch active goal row
        let goals: [GoalRow] = try await db
            .from("goals")
            .select()
            .eq("user_id", value: uuid)
            .eq("is_active", value: true)
            .limit(1)
            .execute()
            .value

        return mapToProfile(row: row, goal: goals.first, userId: userId)
    }

    // MARK: - Mapping

    private func mapToProfile(row: ProfileRow, goal: GoalRow?, userId: String) -> UserProfile {
        var p = UserProfile()
        p.id = userId

        // Split full_name back into first/last
        let parts = (row.full_name ?? "").split(separator: " ", maxSplits: 1)
        p.firstName = parts.indices.contains(0) ? String(parts[0]) : ""
        p.lastName  = parts.indices.contains(1) ? String(parts[1]) : ""

        p.avatarURL     = row.avatar_url
        p.age           = ageFromBirthDate(row.date_of_birth) ?? 25
        p.biologicalSex = BiologicalSex(rawValue: row.gender ?? "male") ?? .male
        p.heightCm      = row.height_cm ?? 170.0
        p.weightKg      = row.weight_kg ?? 70.0
        p.activityLevel = ActivityLevel(rawValue: row.activity_level ?? "moderately_active") ?? .moderatelyActive
        p.weightUnit    = row.units == "metric" ? .kg : .lbs
        p.heightUnit    = row.units == "metric" ? .cm : .ftIn
        p.hasCompletedOnboarding = row.onboarding_done ?? false

        if let g = goal {
            p.goal               = FitnessGoal(rawValue: g.goal_type) ?? .maintenance
            p.targetWeightKg     = g.target_weight_kg
            p.dailyCalorieTarget = g.calorie_target
            p.proteinTargetG     = g.protein_target_g ?? 150
            p.carbsTargetG       = g.carbs_target_g   ?? 200
            p.fatTargetG         = g.fat_target_g      ?? 65
        }

        return p
    }

    // MARK: - Date Helpers

    /// Approximates a birth date string from an age (mid-year, current year minus age).
    private func approximateBirthDate(fromAge age: Int) -> String? {
        guard age > 0 else { return nil }
        let year = Calendar.current.component(.year, from: Date()) - age
        return "\(year)-06-15"
    }

    /// Parses a "YYYY-MM-DD" birth date back to an approximate age.
    private func ageFromBirthDate(_ dateString: String?) -> Int? {
        guard let str = dateString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: str) else { return nil }
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year
    }

    // MARK: - Errors

    enum ProfileError: LocalizedError {
        case missingUserId

        var errorDescription: String? {
            "User ID is missing — make sure sign-in completed before saving profile."
        }
    }
}
