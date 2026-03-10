//
//  TDEECalculator.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//

import Foundation
struct TDEEResult {
    let bmr: Double            // Basal Metabolic Rate
    let tdee: Double           // Total Daily Energy Expenditure
    let targetCalories: Int    // After goal adjustment
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
}

struct TDEECalculator {

    /// Calculates full nutrition targets from a UserProfile
    static func calculate(for profile: UserProfile) -> TDEEResult {
        let bmr = calculateBMR(
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            age: profile.age,
            sex: profile.biologicalSex
        )

        let tdee = bmr * profile.activityLevel.multiplier

        // Apply goal-based calorie adjustment, enforce minimum 1200 cal
        let rawTarget = tdee + profile.goal.calorieAdjustment
        let targetCalories = max(1200, rawTarget)

        // Macros
        let proteinG  = calculateProtein(weightKg: profile.weightKg, goal: profile.goal)
        let fatG      = calculateFat(targetCalories: targetCalories)
        let carbsG    = calculateCarbs(
            targetCalories: targetCalories,
            proteinG: proteinG,
            fatG: fatG
        )

        return TDEEResult(
            bmr: bmr,
            tdee: tdee,
            targetCalories: Int(targetCalories),
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG
        )
    }

    // MARK: - Private helpers

    /// Mifflin-St Jeor BMR
    private static func calculateBMR(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        sex: BiologicalSex
    ) -> Double {
        let base = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))
        switch sex {
        case .male:   return base + 5
        case .female: return base - 161
        }
    }

    /// Protein: goal-based grams per kg of bodyweight
    private static func calculateProtein(weightKg: Double, goal: FitnessGoal) -> Int {
        Int(weightKg * goal.proteinMultiplier)
    }

    /// Fat: ~25% of total calories (9 cal/g)
    private static func calculateFat(targetCalories: Double) -> Int {
        Int((targetCalories * 0.25) / 9)
    }

    /// Carbs: remaining calories after protein and fat (4 cal/g)
    private static func calculateCarbs(
        targetCalories: Double,
        proteinG: Int,
        fatG: Int
    ) -> Int {
        let proteinCals = Double(proteinG) * 4
        let fatCals     = Double(fatG) * 9
        let remaining   = targetCalories - proteinCals - fatCals
        return max(0, Int(remaining / 4))
    }
}
