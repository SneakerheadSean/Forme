//
//  Step4_ActivityView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//

import Foundation
import SwiftUI

struct Step4_ActivityView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    private let icons: [ActivityLevel: String] = [
        .sedentary:         "sofa.fill",
        .lightlyActive:     "figure.walk",
        .moderatelyActive:  "figure.run",
        .veryActive:        "figure.strengthtraining.traditional",
        .extremelyActive:   "bolt.fill"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {

            StepHeader(
                title: OnboardingStep.activityLevel.title,
                subtitle: OnboardingStep.activityLevel.subtitle
            )

            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    SelectionCard(
                        value: level,
                        icon: icons[level] ?? "figure.walk",
                        title: level.displayName,
                        subtitle: level.description,
                        selection: $vm.selectedActivity
                    )
                }
            }

            // TDEE preview teaser
            if let previewCals = estimatedCalories() {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated daily burn")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.4)
                        Text("~\(previewCals) kcal")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.appTextPrimary)
                    }
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.appAccent)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appCard)
                )
                .animation(.spring(response: 0.4), value: vm.selectedActivity)
                .transition(.opacity)
            }
        }
        .padding(.bottom, 24)
    }

    // Live TDEE estimate using current profile draft
    private func estimatedCalories() -> Int? {
        var draft = vm.profile
        draft.activityLevel = vm.selectedActivity
        draft.goal = .maintenance     // show TDEE without adjustment for now

        // Need valid stats to estimate
        guard draft.heightCm > 0, draft.weightKg > 0, draft.age > 0 else { return nil }

        let result = TDEECalculator.calculate(for: draft)
        return Int(result.tdee)
    }
}
