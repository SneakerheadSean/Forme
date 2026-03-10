//
//  Step1_NameView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//

import Foundation
import SwiftUI

struct Step1_NameView: View {
    @EnvironmentObject var vm: OnboardingViewModel

    // Pre-fill Apple name if available from first sign-in
    @State private var didPrefill = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {

            StepHeader(
                title: OnboardingStep.name.title,
                subtitle: OnboardingStep.name.subtitle
            )

            VStack(spacing: 16) {
                AppTextField(
                    label: "First Name",
                    placeholder: "e.g. Alex",
                    text: $vm.firstName
                )

                AppTextField(
                    label: "Last Name",
                    placeholder: "e.g. Johnson",
                    text: $vm.lastName
                )
            }

            // Welcome preview
            if !vm.firstName.isEmpty {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Text(vm.firstName.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appAccent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hey, \(vm.firstName)! 👋")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                        Text("Let's build your personalized plan")
                            .font(.system(size: 13))
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appCard)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: vm.firstName)
            }
        }
        .padding(.bottom, 24)
        .onAppear {
            // Pre-fill from Apple Sign-In if available
            if !didPrefill {
                vm.firstName = UserDefaults.standard.string(forKey: "appleFirstName") ?? ""
                vm.lastName  = UserDefaults.standard.string(forKey: "appleLastName") ?? ""
                didPrefill = true
            }
        }
    }
}
