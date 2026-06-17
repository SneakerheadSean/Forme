//
//  AppLinks.swift
//  Formé
//
//  Central place for external URLs (legal, support).
//  TODO: Replace these with your real hosted URLs before App Store submission.
//        Apple requires a reachable Privacy Policy URL in App Store Connect,
//        and the in-app links below must resolve to live pages.
//

import Foundation

enum AppLinks {
    /// Hosted privacy policy. See legal/privacy-policy.md in the repo for the source text to publish.
    static let privacyPolicy = URL(string: "https://forme.app/legal/privacy")!

    /// Hosted terms of service. See legal/terms-of-service.md in the repo.
    static let termsOfService = URL(string: "https://forme.app/legal/terms")!

    /// Support / contact page (used for the App Store Connect "Support URL").
    static let support = URL(string: "https://forme.app/support")!
}
