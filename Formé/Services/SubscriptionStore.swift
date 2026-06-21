//
//  SubscriptionStore.swift
//  Formé
//
//  StoreKit 2 integration for Formé's freemium tiers.
//
//  - SubscriptionTier: the entitlement levels (Free / Pro / Elite).
//  - ProductID:        the App Store product identifiers. These MUST match the
//                      products in App Store Connect and in Forme.storekit.
//  - SubscriptionStore: app-wide @EnvironmentObject (injected from Forme_App).
//                      Loads products, runs purchases/restores, listens for
//                      transaction updates, and resolves the user's current tier
//                      from StoreKit's current entitlements (the source of truth).
//
//  v1 sells one paid tier (Pro): monthly + annual, with a 7-day free trial on the
//  annual plan. Elite (AI coach, recovery analytics, demonstrations) ships in a
//  later update — its case exists here so gating code can already say `>= .pro`
//  without churn when Elite lands.
//

import Foundation
import Combine
import StoreKit

// MARK: - Tiers

/// Entitlement levels, ordered so callers can gate with `currentTier >= .pro`.
enum SubscriptionTier: Int, Comparable, CaseIterable {
    case free  = 0
    case pro   = 1
    case elite = 2

    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .free:  return "Free"
        case .pro:   return "Pro"
        case .elite: return "Elite"
        }
    }
}

// MARK: - Product identifiers

enum ProductID {
    static let proMonthly = "com.capturethesole.forme.pro.monthly"
    static let proAnnual  = "com.capturethesole.forme.pro.annual"

    /// Identifiers that grant the Pro tier.
    static let proIDs: Set<String> = [proMonthly, proAnnual]

    /// Identifiers that grant the Elite tier (none yet — ships in v1.1).
    static let eliteIDs: Set<String> = []

    /// Every identifier we ask StoreKit to load.
    static let all: [String] = Array(proIDs) + Array(eliteIDs)

    /// The tier a given product unlocks.
    static func tier(for productID: String) -> SubscriptionTier {
        if eliteIDs.contains(productID) { return .elite }
        if proIDs.contains(productID)   { return .pro }
        return .free
    }
}

// MARK: - Store

@MainActor
final class SubscriptionStore: ObservableObject {

    /// Loadable products, sorted cheapest → most expensive.
    @Published private(set) var products: [Product] = []
    /// Identifiers the user currently owns (active, non-revoked).
    @Published private(set) var purchasedProductIDs: Set<String> = []
    /// Highest tier the user is currently entitled to.
    @Published private(set) var currentTier: SubscriptionTier = .free
    @Published private(set) var isLoadingProducts = false

    private var updatesListener: Task<Void, Never>?

    /// Convenience for gating code and previews.
    var isPro: Bool { currentTier >= .pro }

    init() {
        // Start listening before the first entitlement check so we never miss a
        // transaction that arrives during launch (e.g. an Ask-to-Buy approval,
        // or a purchase finished on another device).
        updatesListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit { updatesListener?.cancel() }

    // MARK: Loading

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            // Keep whatever we had; the paywall offers a retry.
        }
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    // MARK: Purchasing

    /// Returns true once the purchase completes and the entitlement is active.
    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshEntitlements()
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// Restores purchases by syncing with the App Store, then re-checks entitlements.
    /// Wired to the "Restore Purchases" row in Profile.
    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: Entitlements

    /// Re-derives `currentTier` / `purchasedProductIDs` from StoreKit's current
    /// entitlements — the authoritative record of what the user owns right now.
    func refreshEntitlements() async {
        var owned: Set<String> = []
        var tier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard transaction.revocationDate == nil else { continue }
            // Guard against expired subscriptions (StoreKit usually omits these).
            if let expiry = transaction.expirationDate, expiry < Date() { continue }
            owned.insert(transaction.productID)
            tier = max(tier, ProductID.tier(for: transaction.productID))
        }

        purchasedProductIDs = owned
        currentTier = tier
    }

    // MARK: Transaction updates

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                guard let transaction = try? self.checkVerified(update) else { continue }
                await self.refreshEntitlements()
                await transaction.finish()
            }
        }
    }

    /// Unwraps a StoreKit verification result, throwing if the signature is invalid.
    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
