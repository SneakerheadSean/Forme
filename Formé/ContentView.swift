//
//  ContentView.swift
//  Formé
//
//  Created by Sean Hughes on 3/2/26.
//
//  Root routing view. Manages three auth/onboarding states:
//   1. Not authenticated          → AuthView
//   2. Authenticated, no profile  → OnboardingContainerView
//   3. Authenticated + onboarded  → MainTabView
//
//  State transitions are driven by:
//   - authService.currentUserId   (Supabase session)
//   - @AppStorage hasCompletedOnboarding (written by OnboardingViewModel on finish)
//
//  NOTE: @AppStorage responds live to UserDefaults changes, so when
//  OnboardingViewModel writes "hasCompletedOnboarding = true" the router
//  automatically transitions to MainTabView without any extra wiring.

import SwiftUI

// MARK: - Root Router

struct ContentView: View {

    @EnvironmentObject var authService: AuthService

    /// Mirrors UserDefaults so the view re-renders the moment onboarding writes this flag.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if authService.currentUserId == nil {
                AuthView()
            } else if !hasCompletedOnboarding {
                OnboardingContainerView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.currentUserId)
        // When the user signs out, clear the onboarding flag so they start fresh on next login.
        .onChange(of: authService.currentUserId) { userId in
            if userId == nil {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            WorkoutScreen()
                .tabItem {
                    Label("Train", systemImage: "figure.strengthtraining.traditional")
                }

            NutritionScreen()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }

            ProfileScreen()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        // Gold accent matches the premium tone used in HomeScreen / ProfileScreen
        .tint(Color(hex: "C4A97D"))
    }
}
