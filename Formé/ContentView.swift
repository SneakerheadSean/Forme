//
//  ContentView.swift
//  Formé
//
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

            Text("Nutrition")
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
        }
    }
}
