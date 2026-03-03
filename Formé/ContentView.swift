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
            HomeView(userName: "Alex") // ← swap "Alex" for your profile var later
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
        }
    }
}
