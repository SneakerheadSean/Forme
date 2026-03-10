//
//  Step5_TargetsView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//  Step5_TargetsView.swift
// Shows calculated calorie + macro targets. Lets user override calories if desired.

import Foundation
import SwiftUI

struct Step5_TargetsView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            StepHeader(
                title: OnboardingStep.targets.title,
                subtitle: OnboardingStep.targets.subtitle
            )

            // Trigger calculation on appear
            if let result = vm.tdeeResult {

                // MARK: Calorie Card
                calorieCard(result: result)

                // MARK: Macro Row
                macroRow(result: result)

                // MARK: How it's calculated
                breakdownCard(result: result)

                // MARK: Manual Override
                overrideSection

            } else {
                ProgressView("Calculating your targets…")
                    .tint(Color.appAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .onAppear { vm.calculateTargets() }
            }
        }
        .padding(.bottom, 24)
        .onAppear { vm.calculateTargets() }
    }

    // MARK: - Calorie Card

    @ViewBuilder
    private func calorieCard(result: TDEEResult) -> some View {
        VStack(spacing: 4) {
            Text("Daily Calorie Target")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            if vm.useCustomCalories {
                HStack {
                    TextField("Calories", text: $vm.customCalories)
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.appAccent)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                    Text("kcal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .padding(.top, 16)
                }
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(result.targetCalories)")
                        .font(.system(size: 56, weight: .black))
                        .foregroundColor(.appTextPrimary)
                    Text("kcal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .padding(.bottom, 10)
                }
            }

            // Goal context
            Text(goalContextLabel)
                .font(.system(size: 13))
                .foregroundColor(goalContextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCard)
        )
    }

    private var goalContextLabel: String {
        switch vm.selectedGoal {
        case .weightLoss:   return "500 kcal below your maintenance"
        case .muscleGain:   return "300 kcal above your maintenance"
        case .maintenance:  return "Matches your maintenance calories"
        case .performance:  return "Slight surplus to fuel performance"
        }
    }

    private var goalContextColor: Color {
        switch vm.selectedGoal {
        case .weightLoss:   return Color(hex: "FF6B6B")
        case .muscleGain:   return Color(hex: "4ECDC4")
        case .maintenance:  return .appTextSecondary
        case .performance:  return Color(hex: "45B7D1")
        }
    }

    // MARK: - Macro Row

    @ViewBuilder
    private func macroRow(result: TDEEResult) -> some View {
        HStack(spacing: 10) {
            MacroBadge(
                label: "Protein",
                value: "\(result.proteinG)",
                unit: "g",
                color: Color(hex: "FF6B6B")
            )
            MacroBadge(
                label: "Carbs",
                value: "\(result.carbsG)",
                unit: "g",
                color: Color(hex: "4ECDC4")
            )
            MacroBadge(
                label: "Fat",
                value: "\(result.fatG)",
                unit: "g",
                color: Color(hex: "FFE66D")
            )
        }
    }

    // MARK: - Breakdown Card

    @ViewBuilder
    private func breakdownCard(result: TDEEResult) -> some View {
        VStack(spacing: 0) {
            breakdownRow(
                label: "Basal Metabolic Rate (BMR)",
                value: "\(Int(result.bmr)) kcal",
                isFirst: true
            )
            Divider().background(Color.appBorder)
            breakdownRow(
                label: "Activity Multiplier (\(vm.selectedActivity.displayName))",
                value: "×\(String(format: "%.2f", vm.selectedActivity.multiplier))",
                isFirst: false
            )
            Divider().background(Color.appBorder)
            breakdownRow(
                label: "TDEE (maintenance)",
                value: "\(Int(result.tdee)) kcal",
                isFirst: false
            )
            if vm.selectedGoal != .maintenance {
                Divider().background(Color.appBorder)
                breakdownRow(
                    label: "\(vm.selectedGoal.displayName) adjustment",
                    value: "\(vm.selectedGoal.calorieAdjustment > 0 ? "+" : "")\(Int(vm.selectedGoal.calorieAdjustment)) kcal",
                    isFirst: false
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCard)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func breakdownRow(label: String, value: String, isFirst: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appTextPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Manual Override

    @ViewBuilder
    private var overrideSection: some View {
        Button {
            withAnimation(.spring(response: 0.35)) {
                vm.useCustomCalories.toggle()
                if vm.useCustomCalories, let result = vm.tdeeResult {
                    vm.customCalories = "\(result.targetCalories)"
                }
            }
        } label: {
            HStack {
                Image(systemName: vm.useCustomCalories ? "arrow.uturn.backward" : "slider.horizontal.3")
                    .font(.system(size: 14))
                Text(vm.useCustomCalories ? "Use recommended calories" : "Set a custom calorie target")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.appAccent)
        }
        .frame(maxWidth: .infinity)
    }
}
