//
//  WorkoutScreen.swift
//  Formé
//
//  Real workout history backed by Supabase (`workout_sessions`). Quick-log a
//  completed session; it persists to Supabase and (if Health sync is on) writes
//  an HKWorkout. A richer set-by-set logger over the exercises/workout_sets
//  tables is a planned future increment.
//

import SwiftUI

// MARK: - Workout Type (raw values match workout_sessions.session_type DB check)

enum WorkoutType: String, CaseIterable, Identifiable {
    case strength, cardio, mixed, flexibility

    var id: String { rawValue }

    var display: String {
        switch self {
        case .strength:    return "Strength"
        case .cardio:      return "Cardio"
        case .mixed:       return "Mixed"
        case .flexibility: return "Flexibility"
        }
    }

    var emoji: String {
        switch self {
        case .strength:    return "🏋️"
        case .cardio:      return "🏃"
        case .mixed:       return "🤸"
        case .flexibility: return "🧘"
        }
    }

    static func emoji(for raw: String?) -> String {
        WorkoutType(rawValue: raw ?? "strength")?.emoji ?? "🏋️"
    }
}

// MARK: - Workout Screen (Train tab)

struct WorkoutScreen: View {
    @EnvironmentObject private var workout: WorkoutStore
    @EnvironmentObject private var health: HealthStore
    @EnvironmentObject private var authService: AuthService

    @State private var showLog = false

    private let gold = Color(hex: "C4A97D")

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    header
                        .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 18)

                    logButton
                        .padding(.horizontal, 16).padding(.bottom, 12)

                    todaySummary
                        .padding(.horizontal, 16)

                    sectionLabel("RECENT SESSIONS")
                        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 10)

                    if workout.recent.isEmpty {
                        emptyState.padding(.horizontal, 16)
                    } else {
                        sessionsCard.padding(.horizontal, 16)
                    }

                    Spacer().frame(height: 28)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(hex: "F7F5F2").ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showLog) {
                QuickLogWorkoutSheet { name, type, minutes, calories in
                    await workout.logWorkout(name: name, sessionType: type.rawValue,
                                             durationMinutes: minutes, calories: calories, health: health)
                }
            }
            .task { if let uid = authService.currentUserId { await workout.load(userId: uid) } }
            .refreshable { if let uid = authService.currentUserId { await workout.load(userId: uid) } }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Training")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Color(UIColor.label))
            Text("LOG YOUR SESSIONS")
                .font(.system(size: 11, weight: .semibold)).tracking(1.4)
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .padding(.top, 6)
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 99).fill(gold).frame(width: 32, height: 1.5)
                Rectangle().fill(Color(UIColor.separator).opacity(0.25)).frame(height: 0.75).padding(.leading, 6)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var logButton: some View {
        Button { showLog = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill").font(.system(size: 16, weight: .bold))
                Text("Log a Workout").font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color(UIColor.label))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var todaySummary: some View {
        HStack(spacing: 18) {
            summaryStat(value: "\(workout.todaySessions.count)", label: "TODAY")
            Divider().frame(height: 32)
            summaryStat(value: "\(workout.todayBurned)", label: "KCAL BURNED")
            Spacer()
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 5)
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .heavy)).foregroundColor(Color(UIColor.label))
            Text(label).font(.system(size: 10, weight: .bold)).tracking(0.8).foregroundColor(.secondary)
        }
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 11, weight: .bold)).tracking(1.4)
            .foregroundColor(Color(UIColor.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Sessions

    private var sessionsCard: some View {
        VStack(spacing: 0) {
            ForEach(workout.recent) { session in
                sessionRow(session)
                if session.id != workout.recent.last?.id {
                    Divider().padding(.leading, 68)
                }
            }
        }
        .padding(.vertical, 6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
    }

    private func sessionRow(_ s: WorkoutSessionRow) -> some View {
        HStack(spacing: 12) {
            Text(WorkoutType.emoji(for: s.session_type))
                .font(.system(size: 17))
                .frame(width: 36, height: 36)
                .background(Color(UIColor.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(s.name).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(UIColor.label))
                Text(subtitle(s)).font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
            }
            Spacer()
            Button { Task { await workout.delete(s) } } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .frame(width: 32, height: 32)
                    .background(Color(UIColor.systemGroupedBackground)).clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10).padding(.horizontal, 20)
    }

    private func subtitle(_ s: WorkoutSessionRow) -> String {
        var parts: [String] = []
        if s.durationMinutes > 0 { parts.append("\(s.durationMinutes) min") }
        if let c = s.calories_burned, c > 0 { parts.append("\(c) kcal") }
        parts.append(relativeDay(s.startedDate))
        return parts.joined(separator: " · ")
    }

    private func relativeDay(_ date: Date?) -> String {
        guard let date else { return "" }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 30)).foregroundColor(gold)
            Text("No workouts logged yet")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(UIColor.label))
            Text("Tap “Log a Workout” after you train to track it here.")
                .font(.system(size: 13)).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
    }
}

// MARK: - Quick Log Workout Sheet

struct QuickLogWorkoutSheet: View {
    /// (name, type, durationMinutes, calories)
    var onSave: (String, WorkoutType, Int, Int) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: WorkoutType = .strength
    @State private var minutes = ""
    @State private var calories = ""
    @State private var saving = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Int(minutes) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    field("WORKOUT NAME") {
                        TextField("e.g. Push day", text: $name).textInputAutocapitalization(.words)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TYPE").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary).tracking(0.8)
                        Picker("Type", selection: $type) {
                            ForEach(WorkoutType.allCases) { Text($0.display).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    HStack(spacing: 12) {
                        field("DURATION (min)") { TextField("0", text: $minutes).keyboardType(.numberPad) }
                        field("CALORIES")       { TextField("0", text: $calories).keyboardType(.numberPad) }
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "F7F5F2").ignoresSafeArea())
            .navigationTitle("Log a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saving = true
                        Task {
                            await onSave(name.trimmingCharacters(in: .whitespaces), type,
                                         Int(minutes) ?? 0, Int(calories) ?? 0)
                            saving = false
                            dismiss()
                        }
                    } label: {
                        if saving { ProgressView() } else { Text("Save").fontWeight(.semibold) }
                    }
                    .disabled(!canSave || saving)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func field<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(.secondary).tracking(0.8)
            content()
                .font(.system(size: 16, weight: .semibold))
                .padding(14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    WorkoutScreen()
        .environmentObject(WorkoutStore())
        .environmentObject(HealthStore())
        .environmentObject(AuthService.shared)
}
