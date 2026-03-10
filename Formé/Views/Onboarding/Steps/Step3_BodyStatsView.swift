//
//  Step3_BodyStatsView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//

import Foundation
import SwiftUI

struct Step3_BodyStatsView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            StepHeader(
                title: OnboardingStep.bodyStats.title,
                subtitle: OnboardingStep.bodyStats.subtitle
            )

            // MARK: Biological Sex
            VStack(alignment: .leading, spacing: 10) {
                Text("Biological Sex")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(spacing: 10) {
                    ForEach(BiologicalSex.allCases, id: \.self) { sex in
                        SexToggleButton(
                            sex: sex,
                            isSelected: vm.biologicalSex == sex
                        ) {
                            vm.biologicalSex = sex
                        }
                    }
                }
            }

            // MARK: Age
            AppTextField(
                label: "Age",
                placeholder: "25",
                text: $vm.age,
                keyboardType: .numberPad,
                autocapitalization: .never
            )

            // MARK: Units Toggle
            VStack(alignment: .leading, spacing: 10) {
                Text("Units")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Picker("Units", selection: $vm.useMetric) {
                    Text("Imperial (lbs / ft)").tag(false)
                    Text("Metric (kg / cm)").tag(true)
                }
                .pickerStyle(.segmented)
                .tint(Color.appAccent)
            }

            // MARK: Height
            if vm.useMetric {
                AppTextField(
                    label: "Height (cm)",
                    placeholder: "175",
                    text: $vm.heightCm,
                    keyboardType: .decimalPad,
                    autocapitalization: .never
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack(spacing: 10) {
                        AppTextField(label: "Feet", placeholder: "5", text: $vm.heightFeet, keyboardType: .numberPad, autocapitalization: .never)
                        AppTextField(label: "Inches", placeholder: "9", text: $vm.heightInches, keyboardType: .numberPad, autocapitalization: .never)
                    }
                }
            }

            // MARK: Weight
            AppTextField(
                label: vm.useMetric ? "Weight (kg)" : "Weight (lbs)",
                placeholder: vm.useMetric ? "72" : "160",
                text: vm.useMetric ? $vm.weightKg : $vm.weightLbs,
                keyboardType: .decimalPad,
                autocapitalization: .never
            )

            // Privacy note
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
                Text("This data is only used to calculate your calorie targets and stays private.")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Sex Toggle Button

private struct SexToggleButton: View {
    let sex: BiologicalSex
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        sex == .male ? "figure.stand" : "figure.stand.dress"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                Text(sex.displayName)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.appAccent : Color.appCard)
            )
            .foregroundColor(isSelected ? .white : .appTextSecondary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
