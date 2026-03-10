//
//  OnBoardingViewModel.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//
// OnboardingViewModel.swift
// Single source of truth for the entire onboarding flow.
// Passed as an @StateObject from OnboardingContainerView.

import Foundation
import SwiftUI
import Combine

enum OnboardingStep: Int, CaseIterable {
    case name           = 0
    case goal           = 1
    case bodyStats      = 2
    case activityLevel  = 3
    case targets        = 4
    case complete       = 5

    var title: String {
        switch self {
        case .name:          return "What's your name?"
        case .goal:          return "What's your goal?"
        case .bodyStats:     return "Tell us about yourself"
        case .activityLevel: return "How active are you?"
        case .targets:       return "Your daily targets"
        case .complete:      return "You're all set!"
        }
    }

    var subtitle: String {
        switch self {
        case .name:          return "We'll personalize your experience"
        case .goal:          return "This shapes your calorie and macro targets"
        case .bodyStats:     return "Used to calculate your energy needs"
        case .activityLevel: return "Be honest — it affects your targets"
        case .targets:       return "Here's what we recommend based on your goals"
        case .complete:      return "Let's start your journey"
        }
    }

    var progress: Double {
        Double(rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var isLast: Bool { self == .complete }
}

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .name
    @Published var profile: UserProfile = UserProfile()

    // Step 1 – Name
    @Published var firstName: String = ""
    @Published var lastName: String  = ""

    // Step 2 – Goal
    @Published var selectedGoal: FitnessGoal = .maintenance

    // Step 3 – Body Stats
    @Published var biologicalSex: BiologicalSex = .male
    @Published var age: String          = "25"
    @Published var heightFeet: String   = "5"
    @Published var heightInches: String = "9"
    @Published var heightCm: String     = "175"
    @Published var weightLbs: String    = "160"
    @Published var weightKg: String     = "72"
    @Published var useMetric: Bool      = false

    // Step 4 – Activity
    @Published var selectedActivity: ActivityLevel = .moderatelyActive

    // Step 5 – Targets (calculated, user can override)
    @Published var tdeeResult: TDEEResult?
    @Published var customCalories: String = ""
    @Published var useCustomCalories: Bool = false

    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var onboardingComplete: Bool = false

    // MARK: - Validation

    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case .name:          return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        case .goal:          return true
        case .bodyStats:     return isBodyStatsValid
        case .activityLevel: return true
        case .targets:       return true
        case .complete:      return true
        }
    }

    private var isBodyStatsValid: Bool {
        guard let a = Int(age), a >= 13, a <= 100 else { return false }

        if useMetric {
            guard let h = Double(heightCm), h >= 100, h <= 250 else { return false }
            guard let w = Double(weightKg), w >= 30, w <= 300  else { return false }
        } else {
            guard let f = Int(heightFeet), f >= 3, f <= 8  else { return false }
            guard let _ = Int(heightInches)                else { return false }
            guard let w = Double(weightLbs), w >= 66       else { return false }
        }
        return true
    }

    // MARK: - Navigation

    func goForward() {
        guard canProceedFromCurrentStep else { return }

        if currentStep == .bodyStats {
            commitBodyStats()
        }

        if currentStep == .activityLevel {
            calculateTargets()
        }

        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentStep = next
            }
        }
    }

    func goBack() {
        if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentStep = prev
            }
        }
    }

    // MARK: - Commit & Calculate

    private func commitBodyStats() {
        profile.biologicalSex = biologicalSex
        profile.age = Int(age) ?? 25

        if useMetric {
            profile.heightCm  = Double(heightCm) ?? 175
            profile.weightKg  = Double(weightKg) ?? 72
            profile.weightUnit = .kg
            profile.heightUnit = .cm
        } else {
            let feet    = Double(heightFeet) ?? 5
            let inches  = Double(heightInches) ?? 9
            profile.heightCm  = ((feet * 12) + inches) * 2.54
            profile.weightKg  = (Double(weightLbs) ?? 160) / 2.20462
            profile.weightUnit = .lbs
            profile.heightUnit = .ftIn
        }
    }

    func calculateTargets() {
        profile.firstName     = firstName.trimmingCharacters(in: .whitespaces)
        profile.lastName      = lastName.trimmingCharacters(in: .whitespaces)
        profile.goal          = selectedGoal
        profile.activityLevel = selectedActivity

        let result = TDEECalculator.calculate(for: profile)
        tdeeResult = result

        profile.dailyCalorieTarget = result.targetCalories
        profile.proteinTargetG     = result.proteinG
        profile.carbsTargetG       = result.carbsG
        profile.fatTargetG         = result.fatG

        customCalories = "\(result.targetCalories)"
    }

    // MARK: - Save & Complete

    func completeOnboarding(userId: String) async {
        isLoading = true
        errorMessage = nil

        // Apply any manual calorie override
        if useCustomCalories, let cal = Int(customCalories), cal >= 1200 {
            profile.dailyCalorieTarget = cal
        }

        profile.id                      = userId
        profile.hasCompletedOnboarding  = true

        do {
            try await ProfileService.shared.saveProfile(profile)
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(userId, forKey: "userId")
            onboardingComplete = true
        } catch {
            errorMessage = "Couldn't save your profile. Please try again."
        }

        isLoading = false
    }
}
