//
//  Step6_CompleteView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//  Step6_CompleteView.swift
// Final onboarding screen — celebration + summary of what's been set up

import Foundation
import SwiftUI

struct Step6_CompleteView: View {
    @EnvironmentObject var vm: OnboardingViewModel
    @State private var animate = false

    var body: some View {
        VStack(spacing: 32) {

            Spacer(minLength: 20)

            // MARK: Icon + Title
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animate ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animate)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 54))
                        .foregroundColor(.appAccent)
                        .scaleEffect(animate ? 1.0 : 0.3)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.2), value: animate)
                }

                VStack(spacing: 8) {
                    Text("You're all set, \(vm.firstName)!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut.delay(0.3), value: animate)

                    Text("Here's your personalized plan")
                        .font(.system(size: 15))
                        .foregroundColor(.appTextSecondary)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut.delay(0.4), value: animate)
                }
            }

            // MARK: Summary Card
            VStack(spacing: 0) {
                summaryRow(
                    icon: "target",
                    iconColor: Color(hex: "FF6B35"),
                    label: "Goal",
                    value: vm.selectedGoal.displayName,
                    isFirst: true
                )
                Divider().background(Color.appBorder).padding(.leading, 56)

                summaryRow(
                    icon: "flame.fill",
                    iconColor: Color(hex: "FF6B6B"),
                    label: "Daily Calories",
                    value: "\(vm.profile.dailyCalorieTarget) kcal",
                    isFirst: false
                )
                Divider().background(Color.appBorder).padding(.leading, 56)

                summaryRow(
                    icon: "chart.bar.fill",
                    iconColor: Color(hex: "4ECDC4"),
                    label: "Macros",
                    value: "P:\(vm.profile.proteinTargetG)g • C:\(vm.profile.carbsTargetG)g • F:\(vm.profile.fatTargetG)g",
                    isFirst: false
                )
                Divider().background(Color.appBorder).padding(.leading, 56)

                summaryRow(
                    icon: "figure.run",
                    iconColor: Color(hex: "45B7D1"),
                    label: "Activity",
                    value: vm.selectedActivity.displayName,
                    isFirst: false
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appCard)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.spring(response: 0.5).delay(0.45), value: animate)

            // MARK: Next steps hint
            VStack(alignment: .leading, spacing: 10) {
                Text("What's next")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                nextStepRow(icon: "fork.knife", text: "Log your first meal in the Nutrition tab")
                nextStepRow(icon: "dumbbell.fill",  text: "Schedule a workout in the Train tab")
                nextStepRow(icon: "chart.line.uptrend.xyaxis", text: "Check your energy balance daily")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
            )
            .opacity(animate ? 1 : 0)
            .animation(.easeOut.delay(0.6), value: animate)

            Spacer(minLength: 20)
        }
        .onAppear { animate = true }
    }

    // MARK: - Summary Row

    @ViewBuilder
    private func summaryRow(
        icon: String,
        iconColor: Color,
        label: String,
        value: String,
        isFirst: Bool
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Next Step Row

    @ViewBuilder
    private func nextStepRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.appAccent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
        }
    }
}
