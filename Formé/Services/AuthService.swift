//
//  AuthService.swift
//  Formé
// Handles Sign in with Apple and Sign in with Google,
// both routing through Supabase Auth.
//  Created by Sean Hughes on 3/5/26.

import Foundation
import Combine
import AuthenticationServices
import GoogleSignIn
import Supabase

@MainActor
final class AuthService: NSObject, ObservableObject {

    static let shared = AuthService()
    private let supabase = SupabaseService.shared.client

    @Published var currentUserId: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private override init() {
        super.init()
        Task { await restoreSession() }
    }

    // MARK: - Session Restore

    /// Called on app launch — if a valid session exists, skip auth screen
    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id.uuidString
        } catch {
            currentUserId = nil
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await supabase.auth.signOut()
            currentUserId = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign in with Apple

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil

        do {
            // Supabase handles the full Apple OAuth flow natively
            // It opens ASWebAuthenticationSession internally
            let session = try await supabase.auth.signInWithOAuth(
                provider: .apple,
                redirectTo: URL(string: "YOUR_APP_SCHEME://login-callback")
            )
            // Note: On success Supabase posts a session — listen via the
            // auth state change listener below.
            // The session variable here may be nil on first launch
            // (handled by authStateChanges listener).
            _ = session
        } catch {
            errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Alternative: Native ASAuthorizationController flow → exchange token with Supabase
    /// Use this if you want the native Apple sheet instead of a web view.
    func signInWithAppleNative(idToken: String, nonce: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            currentUserId = session.user.id.uuidString
        } catch {
            errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Sign in with Google

    /// Call this from a View that has access to a UIViewController
    func signInWithGoogle(presenting viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil

        do {
            // Step 1: Get Google credential
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController
            )

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingGoogleToken
            }
            let accessToken = result.user.accessToken.tokenString

            // Step 2: Exchange with Supabase
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .google,
                    idToken: idToken,
                    accessToken: accessToken
                )
            )
            currentUserId = session.user.id.uuidString

        } catch {
            errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Listen to Auth State Changes

    /// Start this listener in your App entry point or SceneDelegate
    func startAuthStateListener(onChange: @escaping (String?) -> Void) {
        Task {
            for await (_, session) in await supabase.auth.authStateChanges {
                let userId = session?.user.id.uuidString
                await MainActor.run { onChange(userId) }
            }
        }
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case missingGoogleToken

        var errorDescription: String? {
            switch self {
            case .missingGoogleToken: return "Could not retrieve Google ID token."
            }
        }
    }
}
