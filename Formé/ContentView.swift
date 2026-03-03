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
            SummaryCard()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            Text("Workouts") // placeholder for now
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }

            Text("Nutrition") // placeholder for now
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
        }
    }
}
