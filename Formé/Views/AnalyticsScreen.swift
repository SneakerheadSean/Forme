//
//  AnalyticsScreen.swift
//  Formé
//
//  The "Insights" tab — a Pro-only trends dashboard built with Swift Charts over
//  the existing `daily_summaries` + `body_weight_log` data. Free users see the
//  ProLockedScreen upsell instead.
//

import SwiftUI
import Combine
import Charts

// MARK: - View Model

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published var summaries: [DailySummaryRow] = []
    @Published var weights: [BodyWeightRow] = []
    @Published var isLoading = false
    @Published var range: Range = .month

    enum Range: String, CaseIterable, Identifiable {
        case week = "7D", month = "30D", quarter = "90D"
        var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        let since = SummaryDate.string(daysAgo: range.days)
        async let summariesResult = AnalyticsService.shared.dailySummaries(userId: userId, since: since)
        async let weightsResult = AnalyticsService.shared.bodyWeights(userId: userId, since: since)
        summaries = (try? await summariesResult) ?? []
        weights = (try? await weightsResult) ?? []
    }
}

// MARK: - Screen

struct AnalyticsScreen: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var subscriptions: SubscriptionStore
    @StateObject private var vm = AnalyticsViewModel()

    private let gold = Color(hex: "FFAA00")
    private let burn = Color(hex: "F04E2A")
    private let success = Color(hex: "16A34A")
    private let pulse = Color(hex: "2563EB")

    private var weightUnit: WeightUnit { session.profile?.weightUnit ?? .lbs }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isPro {
                    content
                } else {
                    ProLockedScreen(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Insights is Pro",
                        message: "Track your calories, energy balance, and weight trends over time with Forme Pro."
                    )
                }
            }
            .background(Color(hex: "F7F5F2").ignoresSafeArea())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .task(id: reloadKey) { await reload() }
            .refreshable { await reload() }
        }
    }

    private var reloadKey: String { "\(subscriptions.isPro)-\(vm.range.rawValue)" }

    private func reload() async {
        guard subscriptions.isPro, let uid = authService.currentUserId else { return }
        await vm.load(userId: uid)
    }

    // MARK: Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                rangePicker
                    .padding(.top, 4)

                if vm.summaries.isEmpty && vm.weights.isEmpty {
                    emptyState
                } else {
                    statsGrid
                    energyChartCard
                    balanceChartCard
                    if !vm.weights.isEmpty { weightChartCard }
                }

                Color.clear.frame(height: 16)
            }
            .padding(.horizontal, 16)
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $vm.range) {
            ForEach(AnalyticsViewModel.Range.allCases) { r in
                Text(r.rawValue).tag(r)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: Stats

    private var statsGrid: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 12) {
            StatCard(label: "AVG INTAKE", value: "\(avgConsumed)", unit: "kcal", color: gold)
            StatCard(label: "AVG BURNED", value: "\(avgBurned)", unit: "kcal", color: burn)
            StatCard(label: "AVG BALANCE",
                     value: "\(avgBalance >= 0 ? "+" : "")\(avgBalance)",
                     unit: "kcal", color: avgBalance >= 0 ? burn : success)
            StatCard(label: "WORKOUTS", value: "\(totalWorkouts)", unit: "logged", color: pulse)
        }
    }

    // MARK: Charts

    private var energyChartCard: some View {
        ChartCard(title: "Energy In vs Out", subtitle: "Calories consumed and burned per day") {
            Chart {
                ForEach(vm.summaries) { row in
                    LineMark(x: .value("Date", row.date, unit: .day),
                             y: .value("kcal", row.consumed))
                        .foregroundStyle(by: .value("Type", "Consumed"))
                        .interpolationMethod(.catmullRom)
                }
                ForEach(vm.summaries) { row in
                    LineMark(x: .value("Date", row.date, unit: .day),
                             y: .value("kcal", Double(row.burned)))
                        .foregroundStyle(by: .value("Type", "Burned"))
                        .interpolationMethod(.catmullRom)
                }
            }
            .chartForegroundStyleScale(["Consumed": gold, "Burned": burn])
            .chartLegend(position: .bottom, spacing: 8)
            .frame(height: 180)
        }
    }

    private var balanceChartCard: some View {
        ChartCard(title: "Energy Balance", subtitle: "Surplus vs deficit against your target") {
            Chart(vm.summaries) { row in
                BarMark(x: .value("Date", row.date, unit: .day),
                        y: .value("kcal", row.balance))
                    .foregroundStyle(by: .value("State", row.balance >= 0 ? "Surplus" : "Deficit"))
            }
            .chartForegroundStyleScale(["Surplus": burn, "Deficit": success])
            .chartLegend(position: .bottom, spacing: 8)
            .frame(height: 160)
        }
    }

    private var weightChartCard: some View {
        ChartCard(title: "Weight Trend", subtitle: "Body weight in \(weightUnit.rawValue)") {
            Chart(vm.weights) { row in
                LineMark(x: .value("Date", row.date, unit: .day),
                         y: .value(weightUnit.rawValue, displayWeight(row.kg)))
                    .foregroundStyle(pulse)
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", row.date, unit: .day),
                          y: .value(weightUnit.rawValue, displayWeight(row.kg)))
                    .foregroundStyle(pulse)
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(height: 160)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundStyle(gold)
            Text("Not enough data yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(UIColor.label))
            Text("Log meals and workouts and your trends will appear here.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
        .padding(.top, 30)
    }

    // MARK: Derived stats

    private var avgConsumed: Int {
        guard !vm.summaries.isEmpty else { return 0 }
        return Int(vm.summaries.map(\.consumed).reduce(0, +) / Double(vm.summaries.count))
    }
    private var avgBurned: Int {
        guard !vm.summaries.isEmpty else { return 0 }
        return Int(Double(vm.summaries.map(\.burned).reduce(0, +)) / Double(vm.summaries.count))
    }
    private var avgBalance: Int {
        guard !vm.summaries.isEmpty else { return 0 }
        return Int(vm.summaries.map(\.balance).reduce(0, +) / Double(vm.summaries.count))
    }
    private var totalWorkouts: Int { vm.summaries.map(\.workouts).reduce(0, +) }

    private func displayWeight(_ kg: Double) -> Double {
        weightUnit == .lbs ? kg * 2.20462 : kg
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color(UIColor.label))
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Rectangle()
                .fill(color)
                .frame(height: 2)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

// MARK: - Chart Card

private struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(UIColor.label))
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 6)
    }
}
