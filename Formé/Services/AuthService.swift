//
//  AuthService.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//
//  Handles Sign in with Apple (native ASAuthorization flow) and
//  Sign in with Google, both exchanging tokens with Supabase Auth.
//
//  Architecture notes:
//  - Singleton @MainActor class, observed as an @EnvironmentObject.
//  - Automatically starts a Supabase auth-state listener on init so
//    currentUserId stays in sync with session changes (token refresh,
//    sign-out from another device, etc.).
//  - The Google Sign-In URL callback is registered in Forme_App.swift
//    via .onOpenURL { GIDSignIn.sharedInstance.handle(url) }.

import Foundation
import Combine
import AuthenticationServices
import GoogleSignIn
import Supabase

@MainActor
final class AuthService: NSObject, ObservableObject {

    static let shared = AuthService()

    // MARK: - Published State

    @Published var currentUserId: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private

    private let supabase = SupabaseService.shared.client

    // MARK: - Init

    private override init() {
        super.init()
        Task {
            await restoreSession()
            await listenToAuthStateChanges()
        }
    }

    // MARK: - Session Restore

    /// Called on launch — if a valid Supabase session already exists, populate currentUserId
    /// so the root router skips AuthView immediately.
    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id.uuidString
        } catch {
            // No active session — user will see AuthView
            currentUserId = nil
        }
    }

    // MARK: - Auth State Listener

    /// Keeps currentUserId in sync with Supabase session changes
    /// (token refresh, remote sign-out, etc.). Runs for the lifetime of the app.
    private func listenToAuthStateChanges() async {
        for await (_, session) in await supabase.auth.authStateChanges {
            currentUserId = session?.user.id.uuidString
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await supabase.auth.signOut()
            currentUserId = nil
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "appleFirstName")
            defaults.removeObject(forKey: "appleLastName")
            defaults.removeObject(forKey: "appleEmail")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign in with Apple (native flow)

    /// Called from AuthView after the native ASAuthorization sheet succeeds.
    ///
    /// - Parameters:
    ///   - idToken:  The raw identity token string from ASAuthorizationAppleIDCredential.
    ///   - nonce:    The *original* (unhashed) nonce that was SHA-256 hashed and sent to Apple.
    ///               Supabase verifies this server-side for replay protection.
    func signInWithAppleNative(idToken: String, nonce: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

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
    }

    // MARK: - Sign in with Google

    /// Presents the Google sign-in sheet, then exchanges the resulting ID token with Supabase.
    ///
    /// - Parameter viewController: The presenting UIViewController (obtained from the active
    ///   UIWindowScene in GoogleSignInButton).
    func signInWithGoogle(presenting viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Step 1: Google native sign-in
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)

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
            // GIDSignInError.canceled (code 0) is not a real error
            if (error as? GIDSignInError)?.code != .canceled {
                errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case missingGoogleToken

        var errorDescription: String? {
            switch self {
            case .missingGoogleToken:
                return "Could not retrieve Google ID token."
            }
        }
    }
}
