//
//  NutritionStore.swift
//  Formé
//
//  App-wide source of truth for today's meal log. Loaded on launch (and after
//  changes) so both the Nutrition tab and the Home dashboard show the same real
//  totals. Injected as an @EnvironmentObject from Forme_App.
//

import SwiftUI
import Combine

@MainActor
final class NutritionStore: ObservableObject {

    @Published var entries: [MealEntryRow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private(set) var userId: String?

    func load(userId: String) async {
        self.userId = userId
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await NutritionService.shared.todayEntries(userId: userId)
        } catch {
            errorMessage = "Couldn't load today's meals."
        }
    }

    func quickAdd(name: String, calories: Int, protein: Int, carbs: Int, fat: Int, mealType: MealType) async {
        guard let uid = userId else { return }
        do {
            try await NutritionService.shared.quickAdd(
                userId: uid, name: name, calories: calories,
                protein: protein, carbs: carbs, fat: fat, mealType: mealType
            )
            await load(userId: uid)
        } catch {
            errorMessage = "Couldn't save your meal. Please try again."
        }
    }

    func delete(_ entry: MealEntryRow) async {
        guard let uid = userId else { return }
        do {
            try await NutritionService.shared.delete(entryId: entry.id)
            await load(userId: uid)
        } catch {
            errorMessage = "Couldn't delete that meal."
        }
    }

    // MARK: Computed totals (today)

    var consumedCalories: Int { Int(entries.reduce(0) { $0 + $1.calories }.rounded()) }
    var proteinG: Int { Int(entries.reduce(0) { $0 + ($1.protein_g ?? 0) }.rounded()) }
    var carbsG: Int   { Int(entries.reduce(0) { $0 + ($1.carbs_g ?? 0) }.rounded()) }
    var fatG: Int     { Int(entries.reduce(0) { $0 + ($1.fat_g ?? 0) }.rounded()) }

    func entries(for type: MealType) -> [MealEntryRow] {
        entries.filter { $0.meal_type == type.rawValue }
    }
}
