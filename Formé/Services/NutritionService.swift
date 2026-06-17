//
//  NutritionService.swift
//  Formé
//
//  Reads/writes the user's meal log against Supabase (`foods` + `meal_entries`).
//  Quick-add creates a lightweight user-owned `food` and a `meal_entry` that
//  references it (meal_entries.food_id is NOT NULL). Today's totals are computed
//  from the entries; the DB also auto-refreshes `daily_summaries` via triggers.
//

import Foundation
import Supabase

// MARK: - Row Types

struct MealEntryRow: Codable, Identifiable {
    let id: UUID
    let meal_type: String
    let calories: Double
    let protein_g: Double?
    let carbs_g: Double?
    let fat_g: Double?
    let foods: FoodName?

    struct FoodName: Codable { let name: String; let brand: String? }

    var displayName: String { foods?.name ?? "Meal" }
}

// MARK: - Service

final class NutritionService {

    static let shared = NutritionService()
    private init() {}

    private var db: SupabaseClient { SupabaseService.shared.client }

    /// Today's meal entries (with the food name embedded), oldest first.
    func todayEntries(userId: String) async throws -> [MealEntryRow] {
        try await db
            .from("meal_entries")
            // Cast numeric -> float8 so values decode reliably as Double.
            .select("id, meal_type, calories::float8, protein_g::float8, carbs_g::float8, fat_g::float8, foods(name, brand)")
            .eq("user_id", value: userId)
            .eq("logged_date", value: Self.today())
            .order("logged_at", ascending: true)
            .execute()
            .value
    }

    /// Quick-add: create a user-owned food, then a meal entry referencing it.
    func quickAdd(userId: String, name: String, calories: Int,
                  protein: Int, carbs: Int, fat: Int, mealType: MealType) async throws {
        let foodId = try await insertFood(userId: userId, name: name,
                                          calories: calories, protein: protein, carbs: carbs, fat: fat)
        try await insertEntry(userId: userId, foodId: foodId, mealType: mealType,
                              calories: calories, protein: protein, carbs: carbs, fat: fat)
    }

    func delete(entryId: UUID) async throws {
        try await db.from("meal_entries").delete().eq("id", value: entryId.uuidString).execute()
    }

    // MARK: - Private inserts

    private struct FoodInsert: Encodable {
        let user_id: String
        let name: String
        let serving_size_g: Double
        let serving_unit: String
        let calories_per_100g: Double
        let protein_per_100g: Double
        let carbs_per_100g: Double
        let fat_per_100g: Double
        let is_global: Bool
    }

    private struct InsertedID: Decodable { let id: UUID }

    private func insertFood(userId: String, name: String, calories: Int,
                            protein: Int, carbs: Int, fat: Int) async throws -> UUID {
        // serving_size_g = 100 and per-100g values == entered amounts, so a single
        // 100g serving == exactly what the user typed.
        let payload = FoodInsert(
            user_id: userId, name: name,
            serving_size_g: 100, serving_unit: "serving",
            calories_per_100g: Double(calories),
            protein_per_100g: Double(protein),
            carbs_per_100g: Double(carbs),
            fat_per_100g: Double(fat),
            is_global: false
        )
        let inserted: InsertedID = try await db
            .from("foods").insert(payload).select("id").single().execute().value
        return inserted.id
    }

    private struct EntryInsert: Encodable {
        let user_id: String
        let food_id: String
        let meal_type: String
        let serving_qty: Double
        let serving_unit: String
        let amount_g: Double
        let calories: Double
        let protein_g: Double
        let carbs_g: Double
        let fat_g: Double
        let logged_date: String
    }

    private func insertEntry(userId: String, foodId: UUID, mealType: MealType,
                             calories: Int, protein: Int, carbs: Int, fat: Int) async throws {
        let payload = EntryInsert(
            user_id: userId, food_id: foodId.uuidString, meal_type: mealType.rawValue,
            serving_qty: 1, serving_unit: "serving", amount_g: 100,
            calories: Double(calories), protein_g: Double(protein),
            carbs_g: Double(carbs), fat_g: Double(fat),
            logged_date: Self.today()
        )
        try await db.from("meal_entries").insert(payload).execute()
    }

    /// Local calendar date as "yyyy-MM-dd" — matches what we store in logged_date.
    private static func today() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        return f.string(from: Date())
    }
}
