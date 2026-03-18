//
//  Forme_App.swift
//  Formé
//
//  Created by Sean Hughes on 3/2/26.
//
//  Single app entry point.
//  - Creates AuthService as the global @StateObject source of truth
//  - Injects it as an EnvironmentObject so any view can access it
//  - Registers the Google Sign-In URL callback handler

import SwiftUI
import GoogleSignIn

@main
struct FormeApp: App {

    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                // Required for Google Sign-In to handle the OAuth redirect URL.
                // Without this, the GIDSignIn flow will hang after the browser closes.
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
