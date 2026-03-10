//  Full-screen auth entry point — Sign in with Apple (primary) + Google (secondary)
//  AuthView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//

import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct AuthView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showError = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // MARK: Logo + Branding
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.appAccent)
                            .frame(width: 80, height: 80)
                        Image(systemName: "bolt.heart.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 6) {
                        Text("Formé")                          
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                        Text("Train smarter. Eat better. See the connection.")
                            .font(.system(size: 15))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 64)

                Spacer()

                // MARK: Auth Buttons
                VStack(spacing: 12) {

                    // Apple Sign-In (must be first per Apple HIG)
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(16)

                    // Google Sign-In
                    GoogleSignInButton()

                    if authService.isLoading {
                        ProgressView()
                            .tint(Color.appAccent)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)

                // MARK: Legal footer
                Text("By continuing, you agree to our [Terms of Service](https://yourapp.com/terms) and [Privacy Policy](https://yourapp.com/privacy)")
                    .font(.system(size: 12))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
        }
        .alert("Sign-In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authService.errorMessage ?? "Something went wrong. Please try again.")
        }
        .onChange(of: authService.errorMessage) { msg in
            showError = msg != nil
        }
    }

    // MARK: - Apple Sign-In Handler

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let idTokenData = credential.identityToken,
                let idToken = String(data: idTokenData, encoding: .utf8)
            else {
                authService.errorMessage = "Could not retrieve Apple credentials."
                return
            }

            // ⚠️ Apple only provides name on FIRST sign-in. Save it immediately.
            let firstName = credential.fullName?.givenName ?? ""
            let lastName  = credential.fullName?.familyName ?? ""
            if !firstName.isEmpty {
                UserDefaults.standard.set(firstName, forKey: "appleFirstName")
                UserDefaults.standard.set(lastName,  forKey: "appleLastName")
            }

            Task {
                await authService.signInWithAppleNative(
                    idToken: idToken,
                    nonce: ""  // Pass a real nonce if you implement nonce verification
                )
            }

        case .failure(let error):
            // ASAuthorizationError.canceled is not a real error — user tapped cancel
            if (error as? ASAuthorizationError)?.code != .canceled {
                authService.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Google Sign-In Button

struct GoogleSignInButton: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Button {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let vc    = scene.windows.first?.rootViewController else { return }
            Task {
                await authService.signInWithGoogle(presenting: vc)
            }
        } label: {
            HStack(spacing: 12) {
                Image("google_logo")         // Add google_logo.png to your asset catalog
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Continue with Google")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(uiColor: .label))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
}
