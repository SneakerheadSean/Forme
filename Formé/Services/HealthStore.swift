//
//  HealthStore.swift
//  Formé
//
//  HealthKit integration. HealthKitManager wraps HKHealthStore; HealthStore is
//  the app-wide @EnvironmentObject that the UI observes. Sync is opt-in via the
//  "Health App Sync" toggle in Profile (persisted in UserDefaults).
//
//  Phase 3a: read today's active energy → Home "burned" ring.
//  Phase 3b (next): write completed workouts to Health.
//

import Foundation
import Combine
import HealthKit

// MARK: - HealthKit Manager

final class HealthKitManager {

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        guard let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return [] }
        return [energy]
    }

    private var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        return types
    }

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    /// Total active energy (kcal) burned since the start of today.
    func todayActiveEnergy() async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error { continuation.resume(throwing: error); return }
                let kcal = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }
            store.execute(query)
        }
    }
}

// MARK: - Observable Store

@MainActor
final class HealthStore: ObservableObject {

    @Published var burnedToday: Int = 0
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    private static let enabledKey = "healthSyncEnabled"
    private let manager = HealthKitManager()

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    var isAvailable: Bool { manager.isAvailable }

    /// Prompt for authorization (first opt-in) and then read today's data.
    func requestAndRefresh() async {
        guard isEnabled, manager.isAvailable else { return }
        try? await manager.requestAuthorization()
        await refresh()
    }

    /// Read today's burned energy if sync is on (no auth prompt — safe on launch).
    func refresh() async {
        guard isEnabled, manager.isAvailable else {
            burnedToday = 0
            return
        }
        if let kcal = try? await manager.todayActiveEnergy() {
            burnedToday = Int(kcal.rounded())
        }
    }
}
