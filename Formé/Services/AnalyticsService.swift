//
//  AnalyticsService.swift
//  Formé
//
//  Reads the pre-aggregated `daily_summaries` table (auto-maintained by DB
//  triggers on meal/workout changes) and `body_weight_log` to power the Pro
//  Insights screen. No new tables needed — this is read-only over data the app
//  already produces.
//
//  Date columns (`summary_date`, `logged_at`) come back as "yyyy-MM-dd" strings;
//  we decode them as String and parse to Date locally so charting is independent
//  of the client's JSON date strategy.
//

import Foundation
import Supabase

// MARK: - Date parsing

enum SummaryDate {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        return f
    }()

    static func parse(_ s: String) -> Date? { formatter.date(from: String(s.prefix(10))) }
    static func string(daysAgo days: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Row types

struct DailySummaryRow: Codable, Identifiable {
    let id: UUID
    let summary_date: String
    let calories_consumed: Double?
    let calories_burned: Int?
    let net_calories: Double?
    let energy_balance: Double?
    let calorie_target: Int?
    let workout_count: Int?
    let total_workout_mins: Int?

    var date: Date { SummaryDate.parse(summary_date) ?? .distantPast }
    var consumed: Double { calories_consumed ?? 0 }
    var burned: Int { calories_burned ?? 0 }
    var net: Double { net_calories ?? (consumed - Double(burned)) }
    var balance: Double { energy_balance ?? 0 }
    var workouts: Int { workout_count ?? 0 }
}

struct BodyWeightRow: Codable, Identifiable {
    let id: UUID
    let weight_kg: Double?
    let logged_at: String

    var date: Date { SummaryDate.parse(logged_at) ?? .distantPast }
    var kg: Double { weight_kg ?? 0 }
}

// MARK: - Service

final class AnalyticsService {

    static let shared = AnalyticsService()
    private init() {}

    private var db: SupabaseClient { SupabaseService.shared.client }

    /// Daily summaries on/after `since` ("yyyy-MM-dd"), oldest first.
    func dailySummaries(userId: String, since: String) async throws -> [DailySummaryRow] {
        try await db
            .from("daily_summaries")
            // Cast numeric -> float8 so values decode reliably as Double.
            .select("id, summary_date, calories_consumed::float8, calories_burned, net_calories::float8, energy_balance::float8, calorie_target, workout_count, total_workout_mins")
            .eq("user_id", value: userId)
            .gte("summary_date", value: since)
            .order("summary_date", ascending: true)
            .execute()
            .value
    }

    /// Body-weight log entries on/after `since`, oldest first.
    func bodyWeights(userId: String, since: String) async throws -> [BodyWeightRow] {
        try await db
            .from("body_weight_log")
            .select("id, weight_kg::float8, logged_at")
            .eq("user_id", value: userId)
            .gte("logged_at", value: since)
            .order("logged_at", ascending: true)
            .execute()
            .value
    }
}
