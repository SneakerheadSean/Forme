//
//  SupabaseService.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
// Singleton client for all Supabase interactions.
// Replace the placeholder URL and key with your project credentials.

import Foundation
import Supabase

// MARK: - Client

final class SupabaseService {

    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        // ⚠️ Replace these with your actual Supabase project values
        // Found at: https://supabase.com → Your Project → Settings → API
        client = SupabaseClient(
            supabaseURL: URL(string: "https://gqdaczlcxinemjelirip.supabase.co")!,
            supabaseKey: "sb_publishable_1UIZcIynAFeViksiSQML2Q_Q8wC7Cem"
        )
    }
}

// MARK: - Profile Row (matches Supabase table schema)

struct ProfileRow: Codable {
    var id: String
    var first_name: String
    var last_name: String
    var email: String?
    var goal: String
    var biological_sex: String
    var age: Int
    var height_cm: Double
    var weight_kg: Double
    var target_weight_kg: Double?
    var activity_level: String
    var daily_calorie_target: Int
    var protein_target_g: Int
    var carbs_target_g: Int
    var fat_target_g: Int
    var weight_unit: String
    var height_unit: String
    var has_completed_onboarding: Bool
    var created_at: String?
}

// MARK: - Profile Service

final class ProfileService {

    static let shared = ProfileService()

    private init() {}

    /// Upsert profile — safe to call on create or update
    func saveProfile(_ profile: UserProfile) async throws {
        guard let userId = profile.id else {
            throw ProfileError.missingUserId
        }

        let row = ProfileRow(
            id:                         userId,
            first_name:                 profile.firstName,
            last_name:                  profile.lastName,
            email:                      profile.email,
            goal:                       profile.goal.rawValue,
            biological_sex:             profile.biologicalSex.rawValue,
            age:                        profile.age,
            height_cm:                  profile.heightCm,
            weight_kg:                  profile.weightKg,
            target_weight_kg:           profile.targetWeightKg,
            activity_level:             profile.activityLevel.rawValue,
            daily_calorie_target:       profile.dailyCalorieTarget,
            protein_target_g:           profile.proteinTargetG,
            carbs_target_g:             profile.carbsTargetG,
            fat_target_g:               profile.fatTargetG,
            weight_unit:                profile.weightUnit.rawValue,
            height_unit:                profile.heightUnit.rawValue,
            has_completed_onboarding:   profile.hasCompletedOnboarding,
            created_at:                 nil
        )

        try await SupabaseService.shared.client
            .from("profiles")
            .upsert(row)
            .execute()
    }

    /// Fetch profile for the currently authenticated user
    func fetchProfile(userId: String) async throws -> UserProfile? {
        let rows: [ProfileRow] = try await SupabaseService.shared.client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value

        guard let row = rows.first else { return nil }
        return mapRowToProfile(row)
    }

    // MARK: - Mapping

    private func mapRowToProfile(_ row: ProfileRow) -> UserProfile {
        var p = UserProfile()
        p.id                    = row.id
        p.firstName             = row.first_name
        p.lastName              = row.last_name
        p.email                 = row.email
        p.goal                  = FitnessGoal(rawValue: row.goal) ?? .maintenance
        p.biologicalSex         = BiologicalSex(rawValue: row.biological_sex) ?? .male
        p.age                   = row.age
        p.heightCm              = row.height_cm
        p.weightKg              = row.weight_kg
        p.targetWeightKg        = row.target_weight_kg
        p.activityLevel         = ActivityLevel(rawValue: row.activity_level) ?? .moderatelyActive
        p.dailyCalorieTarget    = row.daily_calorie_target
        p.proteinTargetG        = row.protein_target_g
        p.carbsTargetG          = row.carbs_target_g
        p.fatTargetG            = row.fat_target_g
        p.weightUnit            = WeightUnit(rawValue: row.weight_unit) ?? .lbs
        p.heightUnit            = HeightUnit(rawValue: row.height_unit) ?? .ftIn
        p.hasCompletedOnboarding = row.has_completed_onboarding
        return p
    }

    enum ProfileError: Error {
        case missingUserId
    }
}

