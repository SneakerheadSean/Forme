//
//  WorkoutService.swift
//  Formé
//
//  Reads/writes the user's workout sessions in Supabase (`workout_sessions`).
//  Quick-log records a completed session; the Train tab shows real history.
//  (The schema also supports per-set logging via `workout_sets` + the exercise
//  library — a richer set-by-set logger is a future increment.)
//

import Foundation
import Supabase

struct WorkoutSessionRow: Codable, Identifiable {
    let id: UUID
    let name: String
    let session_type: String?
    let calories_burned: Int?
    let duration_seconds: Int?
    let started_at: String?
    let ended_at: String?

    var durationMinutes: Int { (duration_seconds ?? 0) / 60 }

    var startedDate: Date? {
        guard let s = started_at else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }

    var isToday: Bool { startedDate.map { Calendar.current.isDateInToday($0) } ?? false }
}

final class WorkoutService {

    static let shared = WorkoutService()
    private init() {}

    private var db: SupabaseClient { SupabaseService.shared.client }

    func recentSessions(userId: String, limit: Int = 20) async throws -> [WorkoutSessionRow] {
        try await db
            .from("workout_sessions")
            .select("id, name, session_type, calories_burned, duration_seconds, started_at, ended_at")
            .eq("user_id", value: userId)
            .order("started_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    @discardableResult
    func logWorkout(userId: String, name: String, sessionType: String,
                    durationMinutes: Int, calories: Int) async throws -> WorkoutSessionRow {
        let end = Date()
        let start = end.addingTimeInterval(-Double(durationMinutes * 60))
        let iso = ISO8601DateFormatter()

        struct Insert: Encodable {
            let user_id: String
            let name: String
            let session_type: String
            let started_at: String
            let ended_at: String
            let calories_burned: Int
        }
        let payload = Insert(
            user_id: userId, name: name, session_type: sessionType,
            started_at: iso.string(from: start), ended_at: iso.string(from: end),
            calories_burned: calories
        )
        return try await db
            .from("workout_sessions")
            .insert(payload)
            .select("id, name, session_type, calories_burned, duration_seconds, started_at, ended_at")
            .single()
            .execute()
            .value
    }

    func delete(sessionId: UUID) async throws {
        try await db.from("workout_sessions").delete().eq("id", value: sessionId.uuidString).execute()
    }
}
