//
//  OnboardingContainerView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//  Hosts all onboarding steps, progress bar, and back navigation.
//  Presented as a full-screen cover after auth.

import Foundation
import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var vm = OnboardingViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Top Bar
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                // MARK: Step Content
                stepContent
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                    .id(vm.currentStep)  // forces SwiftUI to re-render on step change

                Spacer()

                // MARK: Bottom Actions
                bottomActions
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
        .onChange(of: vm.onboardingComplete) { complete in
            if complete {
                // The parent ContentView observes this and switches to main app
            }
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Back button (hidden on first step)
                if vm.currentStep != .name {
                    Button {
                        vm.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                            .frame(width: 36, height: 36)
                            .background(Color.appCard)
                            .clipShape(Circle())
                    }
                    .transition(.opacity)
                } else {
                    Color.clear.frame(width: 36, height: 36)
                }

                Spacer()

                // Step counter
                if vm.currentStep != .complete {
                    Text("Step \(vm.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count - 1)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
            }

            // Progress bar (hidden on complete screen)
            if vm.currentStep != .complete {
                OnboardingProgressBar(progress: vm.currentStep.progress)
            }
        }
    }

    // MARK: - Step Content Router

    @ViewBuilder
    private var stepContent: some View {
        ScrollView(showsIndicators: false) {
            switch vm.currentStep {
            case .name:          Step1_NameView()
            case .goal:          Step2_GoalView()
            case .bodyStats:     Step3_BodyStatsView()
            case .activityLevel: Step4_ActivityView()
            case .targets:       Step5_TargetsView()
            case .complete:      Step6_CompleteView()
            }
        }
        .padding(.horizontal, 24)
        .environmentObject(vm)
    }

    // MARK: - Bottom Actions

    @ViewBuilder
    private var bottomActions: some View {
        VStack(spacing: 8) {
            if vm.currentStep == .complete {
                PrimaryButton(
                    title: "Go to Dashboard",
                    isLoading: vm.isLoading,
                    isEnabled: true
                ) {
                    guard let userId = authService.currentUserId else { return }
                    Task { await vm.completeOnboarding(userId: userId) }
                }
            } else {
                PrimaryButton(
                    title: vm.currentStep == .targets ? "Confirm Targets" : "Continue",
                    isLoading: false,
                    isEnabled: vm.canProceedFromCurrentStep
                ) {
                    vm.goForward()
                }
            }

            if let error = vm.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
