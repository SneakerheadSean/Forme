//
//  UserProfile.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//

import Foundation
// MARK: - Enums

enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss     = "weight_loss"
    case muscleGain     = "muscle_gain"
    case maintenance    = "maintenance"
    case performance    = "performance"

    var displayName: String {
        switch self {
        case .weightLoss:   return "Lose Weight"
        case .muscleGain:   return "Build Muscle"
        case .maintenance:  return "Maintenance"
        case .performance:  return "Get Fitter"
        }
    }

    var subtitle: String {
        switch self {
        case .weightLoss:   return "Burn fat, reduce body weight"
        case .muscleGain:   return "Build strength and add muscle"
        case .maintenance:  return "Stay at your current weight"
        case .performance:  return "Improve endurance and fitness"
        }
    }

    var icon: String {
        switch self {
        case .weightLoss:   return "flame.fill"
        case .muscleGain:   return "dumbbell.fill"
        case .maintenance:  return "equal.circle.fill"
        case .performance:  return "bolt.fill"
        }
    }

    // Calorie adjustment relative to TDEE
    var calorieAdjustment: Double {
        switch self {
        case .weightLoss:   return -500   // 500 cal deficit
        case .muscleGain:   return +300   // 300 cal surplus
        case .maintenance:  return 0
        case .performance:  return +100   // slight surplus for performance
        }
    }

    // Protein multiplier (grams per kg bodyweight)
    var proteinMultiplier: Double {
        switch self {
        case .weightLoss:   return 2.2
        case .muscleGain:   return 2.4
        case .maintenance:  return 1.8
        case .performance:  return 2.0
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary          = "sedentary"
    case lightlyActive      = "lightly_active"
    case moderatelyActive   = "moderately_active"
    case veryActive         = "very_active"
    case extremelyActive    = "extra_active"

    var displayName: String {
        switch self {
        case .sedentary:        return "Sedentary"
        case .lightlyActive:    return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive:       return "Very Active"
        case .extremelyActive:  return "Extremely Active"
        }
    }

    var description: String {
        switch self {
        case .sedentary:        return "Little or no exercise"
        case .lightlyActive:    return "Light exercise 1–3 days/week"
        case .moderatelyActive: return "Moderate exercise 3–5 days/week"
        case .veryActive:       return "Hard exercise 6–7 days/week"
        case .extremelyActive:  return "Twice daily or physical job"
        }
    }

    // Mifflin-St Jeor multipliers
    var multiplier: Double {
        switch self {
        case .sedentary:        return 1.2
        case .lightlyActive:    return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive:       return 1.725
        case .extremelyActive:  return 1.9
        }
    }
}

enum BiologicalSex: String, CaseIterable, Codable {
    case male   = "male"
    case female = "female"

    var displayName: String {
        switch self {
        case .male:   return "Male"
        case .female: return "Female"
        }
    }
}

enum WeightUnit: String, CaseIterable, Codable {
    case kg  = "kg"
    case lbs = "lbs"
}

enum HeightUnit: String, CaseIterable, Codable {
    case cm      = "cm"
    case ftIn    = "ft/in"
}

// MARK: - UserProfile

struct UserProfile: Codable, Equatable {
    var id: String?
    var firstName: String           = ""
    var lastName: String            = ""
    var email: String?
    var avatarURL: String?

    // Goals & stats
    var goal: FitnessGoal           = .maintenance
    var biologicalSex: BiologicalSex = .male
    var age: Int                    = 25
    var heightCm: Double            = 170.0
    var weightKg: Double            = 70.0
    var targetWeightKg: Double?

    // Activity
    var activityLevel: ActivityLevel = .moderatelyActive

    // Calculated targets (set after onboarding)
    var dailyCalorieTarget: Int     = 2000
    var proteinTargetG: Int         = 150
    var carbsTargetG: Int           = 200
    var fatTargetG: Int             = 65

    // Preferences
    var weightUnit: WeightUnit      = .lbs
    var heightUnit: HeightUnit      = .ftIn

    // State
    var hasCompletedOnboarding: Bool = false
    var createdAt: Date?

    // MARK: Computed helpers

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var displayWeight: String {
        weightUnit == .lbs
            ? String(format: "%.1f lbs", weightKg * 2.20462)
            : String(format: "%.1f kg", weightKg)
    }

    var displayHeight: String {
        if heightUnit == .ftIn {
            let totalInches = heightCm / 2.54
            let feet  = Int(totalInches / 12)
            let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            return "\(feet)'\(inches)\""
        } else {
            return "\(Int(heightCm)) cm"
        }
    }
}
