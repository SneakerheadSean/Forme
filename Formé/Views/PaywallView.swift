//
//  PaywallView.swift
//  Formé
//
//  The Forme Pro paywall. Presented when a Free user taps a locked feature
//  (Apple Health sync, meal logging, analytics) or the "Forme Pro" upsell.
//
//  Reads products from SubscriptionStore (loaded from StoreKit / Forme.storekit)
//  and runs the purchase + restore flows through it. Apple requires the paywall
//  to surface the subscription length, price, an auto-renew disclosure, and
//  working Terms + Privacy links — all present below.
//
//  v1 sells one tier (Pro): monthly + annual, 7-day free trial on annual.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptions: SubscriptionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var selectedProductID = ProductID.proAnnual
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    private enum Brand {
        static let soleil       = Color(hex: "FFAA00")
        static let soleilLight  = Color(hex: "FFC233")
        static let soleilDeep   = Color(hex: "E09400")
        static let bg           = Color(hex: "F7F5F2")
        static let ink          = Color(UIColor.label)
        static let inkSecondary = Color(UIColor.secondaryLabel)
        static let inkTertiary  = Color(UIColor.tertiaryLabel)
        static let onGold       = Color(hex: "141410")
        static let card         = Color.white
    }

    private let benefits: [(icon: String, title: String, subtitle: String)] = [
        ("heart.fill", "Apple Health sync", "Auto-import active energy and write your workouts back to Health."),
        ("fork.knife", "Meal logging", "Log food, calories, and macros every day."),
        ("chart.line.uptrend.xyaxis", "Trends & analytics", "See calories, energy balance, and weight over time.")
    ]

    private var monthly: Product? { subscriptions.product(for: ProductID.proMonthly) }
    private var annual: Product?  { subscriptions.product(for: ProductID.proAnnual) }
    private var selected: Product? { subscriptions.product(for: selectedProductID) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Brand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    benefitsList
                    plans
                    cta
                    legal
                    Color.clear.frame(height: 16)
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
            }

            closeButton
        }
        .task {
            if subscriptions.products.isEmpty { await subscriptions.loadProducts() }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Brand.soleilLight, Brand.soleilDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                    .shadow(color: Brand.soleil.opacity(0.4), radius: 16, y: 8)
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Brand.onGold)
            }
            .padding(.top, 8)

            Text("Forme Pro")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(Brand.ink)

            Text("Unlock the full Forme experience.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Brand.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Benefits

    private var benefitsList: some View {
        VStack(spacing: 14) {
            ForEach(benefits, id: \.title) { benefit in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Brand.soleil.opacity(0.14))
                            .frame(width: 40, height: 40)
                        Image(systemName: benefit.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Brand.soleilDeep)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Brand.ink)
                        Text(benefit.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Brand.inkTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(18)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
    }

    // MARK: Plans

    @ViewBuilder private var plans: some View {
        if subscriptions.products.isEmpty {
            VStack(spacing: 10) {
                if subscriptions.isLoadingProducts {
                    ProgressView().tint(Brand.soleilDeep)
                } else {
                    Text("Plans are unavailable right now.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Brand.inkSecondary)
                    Button("Retry") { Task { await subscriptions.loadProducts() } }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Brand.soleilDeep)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            VStack(spacing: 12) {
                if let annual {
                    PlanCard(
                        title: "Annual",
                        price: annual.displayPrice,
                        period: "per year",
                        badge: savingsBadge,
                        footnote: trialText(for: annual),
                        isSelected: selectedProductID == annual.id
                    ) { selectedProductID = annual.id }
                }
                if let monthly {
                    PlanCard(
                        title: "Monthly",
                        price: monthly.displayPrice,
                        period: "per month",
                        badge: nil,
                        footnote: trialText(for: monthly),
                        isSelected: selectedProductID == monthly.id
                    ) { selectedProductID = monthly.id }
                }
            }
        }
    }

    // MARK: CTA

    @ViewBuilder private var cta: some View {
        VStack(spacing: 10) {
            Button(action: buy) {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(Brand.onGold)
                    } else {
                        Text(ctaTitle)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(Brand.onGold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    LinearGradient(colors: [Brand.soleilLight, Brand.soleilDeep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing || selected == nil)
            .opacity(selected == nil ? 0.5 : 1)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "F04E2A"))
                    .multilineTextAlignment(.center)
            }

            Text(autoRenewDisclosure)
                .font(.system(size: 11))
                .foregroundStyle(Brand.inkTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    // MARK: Legal / restore

    private var legal: some View {
        HStack(spacing: 18) {
            Button {
                Task { await restore() }
            } label: {
                if isRestoring {
                    ProgressView().controlSize(.small).tint(Brand.inkSecondary)
                } else {
                    Text("Restore")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Brand.inkSecondary)
                }
            }
            .buttonStyle(.plain)

            Button("Terms") { openURL(AppLinks.termsOfService) }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.inkSecondary)
                .buttonStyle(.plain)

            Button("Privacy") { openURL(AppLinks.privacyPolicy) }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.inkSecondary)
                .buttonStyle(.plain)
        }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Brand.inkSecondary)
                .padding(10)
                .background(Brand.card, in: Circle())
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.top, 14)
        .padding(.trailing, 18)
    }

    // MARK: Logic

    private var ctaTitle: String {
        if let selected, trialText(for: selected) != nil { return "Start Free Trial" }
        return "Continue"
    }

    private var autoRenewDisclosure: String {
        "Subscription auto-renews until cancelled. Cancel anytime in Settings. Payment is charged to your Apple Account."
    }

    private var savingsBadge: String? {
        guard let m = monthly?.price, let a = annual?.price, m > 0 else { return nil }
        let yearlyAtMonthly = m * Decimal(12)
        guard yearlyAtMonthly > 0 else { return nil }
        let savedFraction = (yearlyAtMonthly - a) / yearlyAtMonthly
        let pct = Int((savedFraction as NSDecimalNumber).doubleValue * 100)
        return pct > 0 ? "SAVE \(pct)%" : nil
    }

    private func trialText(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let p = offer.period
        let days: Int
        switch p.unit {
        case .day:   days = p.value
        case .week:  days = p.value * 7
        case .month: days = p.value * 30
        case .year:  days = p.value * 365
        @unknown default: days = p.value
        }
        return "\(days)-day free trial, then \(product.displayPrice)/year"
    }

    private func buy() {
        guard let product = selected else { return }
        isPurchasing = true
        errorMessage = nil
        Task {
            defer { isPurchasing = false }
            do {
                if try await subscriptions.purchase(product) { dismiss() }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        try? await subscriptions.restore()
        if subscriptions.isPro { dismiss() }
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let badge: String?
    let footnote: String?
    let isSelected: Bool
    let onTap: () -> Void

    private let soleil = Color(hex: "FFAA00")
    private let soleilDeep = Color(hex: "E09400")
    private let ink = Color(UIColor.label)
    private let inkSecondary = Color(UIColor.secondaryLabel)
    private let inkTertiary = Color(UIColor.tertiaryLabel)

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? soleilDeep : inkTertiary.opacity(0.5), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(soleilDeep).frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ink)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(Color(hex: "141410"))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(soleil, in: Capsule())
                        }
                    }
                    if let footnote {
                        Text(footnote)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(soleilDeep)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(ink)
                    Text(period)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(inkSecondary)
                }
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? soleilDeep : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pro Locked Screen

/// Full-screen upsell shown in place of a Pro-only tab/screen for Free users.
/// Reused by the Nutrition tab and the Analytics screen.
struct ProLockedScreen: View {
    let icon: String
    let title: String
    let message: String

    @State private var showPaywall = false

    private let soleilLight = Color(hex: "FFC233")
    private let soleilDeep  = Color(hex: "E09400")
    private let onGold      = Color(hex: "141410")

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(colors: [soleilLight, soleilDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                    .shadow(color: soleilDeep.opacity(0.35), radius: 16, y: 8)
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(onGold)
                    .frame(width: 84, height: 84)
                ZStack {
                    Circle().fill(Color.white).frame(width: 30, height: 30)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(soleilDeep)
                }
                .offset(x: 4, y: 4)
            }

            Text(title)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(Color(UIColor.label))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(UIColor.secondaryLabel))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button { showPaywall = true } label: {
                Text("Unlock Forme Pro")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(onGold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [soleilLight, soleilDeep],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}
