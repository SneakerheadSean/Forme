//
//  Step2_GoalView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//

import Foundation
import SwiftUI

struct Step2_GoalView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {

            StepHeader(
                title: OnboardingStep.goal.title,
                subtitle: OnboardingStep.goal.subtitle
            )

            VStack(spacing: 12) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    SelectionCard(
                        value: goal,
                        icon: goal.icon,
                        title: goal.displayName,
                        subtitle: goal.subtitle,
                        selection: $vm.selectedGoal
                    )
                }
            }

            // Contextual tip
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.appAccent)

                Text("You can always change this later in your profile settings.")
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appAccent.opacity(0.08))
            )
        }
        .padding(.bottom, 24)
    }
}
