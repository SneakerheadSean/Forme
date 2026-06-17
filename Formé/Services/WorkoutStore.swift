//
//  WorkoutStore.swift
//  Formé
//
//  App-wide source of truth for the user's workout sessions. Logging a workout
//  persists it to Supabase and (if Health sync is enabled) writes an HKWorkout.
//

import SwiftUI
import Combine

@MainActor
final class WorkoutStore: ObservableObject {

    @Published var recent: [WorkoutSessionRow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private(set) var userId: String?

    func load(userId: String) async {
        self.userId = userId
        isLoading = true
        defer { isLoading = false }
        do {
            recent = try await WorkoutService.shared.recentSessions(userId: userId)
        } catch {
            errorMessage = "Couldn't load your workouts."
        }
    }

    func logWorkout(name: String, sessionType: String, durationMinutes: Int, calories: Int, health: HealthStore) async {
        guard let uid = userId else { return }
        do {
            try await WorkoutService.shared.logWorkout(
                userId: uid, name: name, sessionType: sessionType,
                durationMinutes: durationMinutes, calories: calories
            )
            // Mirror to Apple Health (no-op if sync disabled).
            let end = Date()
            await health.saveWorkout(
                sessionType: sessionType,
                start: end.addingTimeInterval(-Double(durationMinutes * 60)),
                end: end, calories: Double(calories)
            )
            await load(userId: uid)
        } catch {
            errorMessage = "Couldn't save your workout. Please try again."
        }
    }

    func delete(_ session: WorkoutSessionRow) async {
        guard let uid = userId else { return }
        do {
            try await WorkoutService.shared.delete(sessionId: session.id)
            await load(userId: uid)
        } catch {
            errorMessage = "Couldn't delete that workout."
        }
    }

    var todaySessions: [WorkoutSessionRow] { recent.filter { $0.isToday } }
    var todayBurned: Int { todaySessions.reduce(0) { $0 + ($1.calories_burned ?? 0) } }
}
