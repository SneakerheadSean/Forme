//
//  ContentView.swift
//  Formé
//  Root view. Handles three states:
//   1. Not authenticated → AuthView
//   2. Authenticated but not onboarded → OnboardingContainerView
//   3. Authenticated + onboarded → Your existing MainTabView
//  Created by Sean Hughes on 3/2/26.
//

import SwiftUI
struct ContentView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem { Label("Home", systemImage: "house.fill") }

            WorkoutScreen()
                .tabItem { Label("Train", systemImage: "figure.strengthtraining.traditional") }

            NutritionScreen()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
        }
    }
}
