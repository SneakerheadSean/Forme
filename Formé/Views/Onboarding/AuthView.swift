//
//  AuthView.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//
//  Full-screen auth entry point.
//  Sign in with Apple (primary, per Apple HIG) + Sign in with Google.
//
//  Security: Apple Sign-In uses a cryptographically random nonce that is
//  SHA-256 hashed before being sent to Apple. The original nonce is held in
//  @State and forwarded to Supabase to verify the token server-side, preventing
//  replay attacks. See Apple's "Preventing replay attacks" documentation.

import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - AuthView

struct AuthView: View {

    @EnvironmentObject var authService: AuthService
    @State private var showError = false

    /// The raw (unhashed) nonce generated just before Apple's authorization request.
    /// Stored in @State so it's available in the completion handler.
    @State private var currentNonce: String?

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

                    // Apple Sign-In must appear first per Apple HIG
                    SignInWithAppleButton(.signIn) { request in
                        // 1. Generate a fresh nonce for this request
                        guard let nonce = randomNonceString() else {
                            authService.errorMessage = "Unable to start Apple Sign-In. Please try again."
                            return
                        }
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        // 2. Send the SHA-256 hash to Apple (not the raw nonce)
                        request.nonce = sha256(nonce)
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

                // MARK: Legal Footer
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
        defer { currentNonce = nil } // avoid reusing nonce across attempts

        switch result {
        case .success(let auth):
            guard
                let credential   = auth.credential as? ASAuthorizationAppleIDCredential,
                let idTokenData  = credential.identityToken,
                let idToken      = String(data: idTokenData, encoding: .utf8),
                let nonce        = currentNonce
            else {
                authService.errorMessage = "Could not retrieve valid Apple credentials."
                return
            }

            // Apple only provides the full name on the very first sign-in.
            // Persist it immediately so the onboarding name step can pre-fill it.
            if let firstName = credential.fullName?.givenName, !firstName.isEmpty {
                UserDefaults.standard.set(firstName, forKey: "appleFirstName")
                UserDefaults.standard.set(credential.fullName?.familyName ?? "", forKey: "appleLastName")
            }
            if let email = credential.email, !email.isEmpty {
                UserDefaults.standard.set(email, forKey: "appleEmail")
            }

            Task {
                await authService.signInWithAppleNative(idToken: idToken, nonce: nonce)
            }

        case .failure(let error):
            // ASAuthorizationError.canceled means the user dismissed the sheet — not an error
            if (error as? ASAuthorizationError)?.code != .canceled {
                authService.errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Nonce Helpers

    /// Generates a cryptographically random alphanumeric nonce of the given length.
    private func randomNonceString(length: Int = 32) -> String? {
        var randomBytes = [UInt8](repeating: 0, count: length)
        let result = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard result == errSecSuccess else {
            return nil
        }

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// Returns the lowercase hex SHA-256 digest of `input`.
    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Google Sign-In Button

struct GoogleSignInButton: View {

    @EnvironmentObject var authService: AuthService

    var body: some View {
        Button {
            guard
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let vc    = scene.windows.first?.rootViewController
            else { return }

            Task {
                await authService.signInWithGoogle(presenting: vc)
            }
        } label: {
            HStack(spacing: 12) {
                // Add google_logo.png (20 × 20 pt) to your asset catalog
                Image("google_logo")
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
