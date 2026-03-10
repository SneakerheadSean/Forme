//
//  WorkoutScreen.swift
//  Formé
//
//  Created by Sean Hughes on 3/3/26.
//

import Foundation
import SwiftUI

// ============================================================
// MARK: - Workout Models
// ============================================================

enum ExerciseType {
    case strength
    case cardio
}

struct SetEntry: Identifiable {
    let id = UUID()
    var reps: String   = ""
    var weight: String = ""
    var completed: Bool = false
}

struct CardioEntry {
    var duration: String  = ""   // minutes
    var distance: String  = ""   // km or miles
    var completed: Bool   = false
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let type: ExerciseType
    let targetSets: Int
    let targetReps: String    // e.g. "8–12"
    let targetWeight: String  // e.g. "60 kg" or "Bodyweight"
    let targetDuration: String  // for cardio e.g. "20 min"
    let targetDistance: String  // for cardio e.g. "3 km"
    let notes: String
}

struct ActiveWorkoutPlan: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let dayNumber: Int
    let totalDays: Int
    let totalWeeks: Int
    let currentWeek: Int
    let type: String
    let difficulty: String
    let durationMinutes: Int
    let estimatedKcal: Int
    let exercises: [Exercise]
    // For the hero: all days in week
    let weekDays: [WeekDay]
}

struct WeekDay: Identifiable {
    let id = UUID()
    let label: String   // "M", "T", "W" etc.
    let status: DayStatus
}

enum DayStatus {
    case completed, today, upcoming, rest
}

extension ActiveWorkoutPlan {
    static let mock = ActiveWorkoutPlan(
        name: "Chest & Shoulders",
        category: "Push · Upper Power",
        dayNumber: 4,
        totalDays: 28,
        totalWeeks: 4,
        currentWeek: 1,
        type: "Strength",
        difficulty: "Intermediate",
        durationMinutes: 52,
        estimatedKcal: 340,
        exercises: [
            Exercise(name: "Bench Press", type: .strength,
                     targetSets: 4, targetReps: "8–10", targetWeight: "70 kg",
                     targetDuration: "", targetDistance: "",
                     notes: "Control the descent. 2 sec down."),
            Exercise(name: "Overhead Press", type: .strength,
                     targetSets: 3, targetReps: "10–12", targetWeight: "45 kg",
                     targetDuration: "", targetDistance: "",
                     notes: "Keep core tight, avoid arching lower back."),
            Exercise(name: "Incline DB Fly", type: .strength,
                     targetSets: 3, targetReps: "12–15", targetWeight: "16 kg",
                     targetDuration: "", targetDistance: "",
                     notes: "Wide arc, squeeze at the top."),
            Exercise(name: "Lateral Raises", type: .strength,
                     targetSets: 4, targetReps: "15", targetWeight: "10 kg",
                     targetDuration: "", targetDistance: "",
                     notes: "Slight bend in elbow. Lead with elbows."),
            Exercise(name: "Tricep Dips", type: .strength,
                     targetSets: 3, targetReps: "To failure", targetWeight: "Bodyweight",
                     targetDuration: "", targetDistance: "",
                     notes: "Keep body close to bench. Full range."),
        ],
        weekDays: [
            WeekDay(label: "M", status: .completed),
            WeekDay(label: "T", status: .completed),
            WeekDay(label: "W", status: .rest),
            WeekDay(label: "T", status: .today),
            WeekDay(label: "F", status: .upcoming),
            WeekDay(label: "S", status: .upcoming),
            WeekDay(label: "S", status: .rest),
        ]
    )
}

// ============================================================
// MARK: - Active Plan Hero Card
// ============================================================

private struct ActivePlanHeroCard: View {
    let plan: ActiveWorkoutPlan
    @State private var progressWidth: CGFloat = 0
    @State private var appeared = false

    private var progressPct: CGFloat {
        CGFloat(plan.dayNumber - 1) / CGFloat(plan.totalDays)
    }
    private var safeProgressPct: CGFloat {
        guard plan.totalDays > 0 else { return 0 }
        let raw = CGFloat(max(0, plan.dayNumber - 1)) / CGFloat(plan.totalDays)
        return min(max(raw, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Top row: plan tag + week label
            HStack {
                Label("28-Day Plan", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(Color(hex: "#C4A97D"))
                Spacer()
                Text("WEEK \(plan.currentWeek) OF \(plan.totalWeeks)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }

            // ── Plan name
            Text("Upper Power\nPush Pull Legs")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(Color(UIColor.label))
                .lineSpacing(2)
                .padding(.top, 12)

            // ── Overall progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Day \(plan.dayNumber) of \(plan.totalDays)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Spacer()
                    Text("\(Int(progressPct * 100))% complete")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#C4A97D"))
                }

                GeometryReader { geo in
                    // Using safeProgressPct to avoid NaN/invalid widths during layout
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(UIColor.systemGroupedBackground))
                            .frame(height: 5)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#C4A97D"), Color(hex: "#E8C99A")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geo.size.width, safeProgressPct * geo.size.width)), height: 5)
                            .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2), value: progressWidth)
                    }
                }
                .frame(height: 5)
            }
            .padding(.top, 16)

            // ── Week day pills
            HStack(spacing: 6) {
                ForEach(plan.weekDays) { day in
                    WeekDayPill(day: day)
                }
            }
            .padding(.top, 16)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4), value: appeared)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
                print("ActivePlanHeroCard progress:", "day=\(plan.dayNumber)", "total=\(plan.totalDays)", "safe=\(safeProgressPct)")
                progressWidth = safeProgressPct
            }
        }
    }
}

private struct WeekDayPill: View {
    let day: WeekDay

    var bg: Color {
        switch day.status {
        case .completed: return Color(hex: "#1C1C1E")
        case .today:     return Color(hex: "#C4A97D")
        case .upcoming:  return Color(UIColor.systemGroupedBackground)
        case .rest:      return Color(UIColor.systemGroupedBackground)
        }
    }

    var fg: Color {
        switch day.status {
        case .completed: return .white
        case .today:     return .white
        case .upcoming:  return Color(UIColor.tertiaryLabel)
        case .rest:      return Color(UIColor.quaternaryLabel)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(day.label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(fg)
            if day.status == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.white)
            } else if day.status == .rest {
                Image(systemName: "minus")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Color(UIColor.quaternaryLabel))
            } else {
                Circle()
                    .fill(day.status == .today ? Color.white.opacity(0.7) : Color.clear)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// ============================================================
// MARK: - Today's Session Card  (compact version for Workout tab)
// ============================================================

private struct TodaySessionCard: View {
    let plan: ActiveWorkoutPlan
    let onStart: () -> Void
    @State private var appeared = false
    @State private var pressed  = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    Text("DAY \(plan.dayNumber) OF \(plan.totalDays)")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.7)
                        .foregroundColor(Color(hex: "#C0703A"))
                        .padding(.horizontal, 11).padding(.vertical, 5)
                        .background(Color(hex: "#FFF0E8"))
                        .clipShape(Capsule())
                    Spacer()
                    Text(plan.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }

                Text(plan.name)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(UIColor.label))
                    .padding(.top, 12)

                HStack(spacing: 5) {
                    Text("~\(plan.durationMinutes) min")
                    Text("·").foregroundColor(Color(UIColor.tertiaryLabel))
                    Text(plan.type)
                    Text("·").foregroundColor(Color(UIColor.tertiaryLabel))
                    Text(plan.difficulty)
                }
                .font(.system(size: 13))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.top, 5)

                // Exercise list — compact text style
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(plan.exercises.enumerated()), id: \.offset) { i, ex in
                        HStack(spacing: 8) {
                            Text("\(i + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#C4A97D"))
                                .frame(width: 16)
                            Text(ex.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(UIColor.label))
                            Spacer()
                            Text(ex.type == .strength
                                 ? "\(ex.targetSets)×\(ex.targetReps)"
                                 : ex.targetDuration)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                }
                .padding(.top, 14)
            }
            .padding(20)

            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.3))
                .frame(height: 0.5)

            HStack {
                Text({
                    var a = AttributedString("Est. ")
                    a.foregroundColor = Color(UIColor.secondaryLabel)

                    var kcal = AttributedString("\(plan.estimatedKcal) kcal")
                    kcal.font = .system(size: 14, weight: .bold)
                    kcal.foregroundColor = Color(UIColor.label)

                    var tail = AttributedString(" burned")
                    tail.foregroundColor = Color(UIColor.secondaryLabel)

                    var result = a
                    result += kcal
                    result += tail
                    return result
                }())
                .font(.system(size: 13))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) { pressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                        withAnimation { pressed = false }
                        onStart()
                    }
                } label: {
                    Text("Start Workout")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 13)
                        .background(Color(UIColor.label))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .scaleEffect(pressed ? 0.94 : 1.0)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.12), value: appeared)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
    }
}

// ============================================================
// MARK: - Workout Screen (Tab root)
// ============================================================

struct WorkoutScreen: View {
    @State private var plan: ActiveWorkoutPlan = .mock
    @State private var navigateToActive = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    workoutHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    // ── Active plan hero
                    sectionLabel("My Plan")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)

                    ActivePlanHeroCard(plan: plan)
                        .padding(.horizontal, 16)

                    // ── Today's session
                    sectionLabel("Today's Session")
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 10)

                    TodaySessionCard(plan: plan) {
                        navigateToActive = true
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 28)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(hex: "#F7F5F2").ignoresSafeArea())
            .navigationDestination(isPresented: $navigateToActive) {
                ActiveWorkoutScreen(plan: plan)
            }
        }
    }

    private var workoutHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Training")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(Color(UIColor.label))

            Text("Upper Power · 28-Day Program".uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .padding(.top, 6)

            // Gold divider
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 99)
                    .fill(Color(hex: "#C4A97D"))
                    .frame(width: 32, height: 1.5)
                Rectangle()
                    .fill(Color(UIColor.separator).opacity(0.25))
                    .frame(height: 0.75)
                    .padding(.leading, 6)
            }
            .padding(.top, 14)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.4)
            .foregroundColor(Color(UIColor.secondaryLabel))
    }
}

// ============================================================
// MARK: - Active Workout Screen
// ============================================================

struct ActiveWorkoutScreen: View {
    let plan: ActiveWorkoutPlan

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var sets: [[SetEntry]]
    @State private var showFinishAlert = false
    @State private var slideDirection: Int = 1  // 1 = forward, -1 = back
    @State private var isTransitioning = false

    init(plan: ActiveWorkoutPlan) {
        self.plan = plan
        _sets = State(initialValue: plan.exercises.map { ex in
            (0..<ex.targetSets).map { _ in SetEntry() }
        })
    }

    private var currentExercise: Exercise { plan.exercises[currentIndex] }
    private var isLast: Bool  { currentIndex == plan.exercises.count - 1 }
    private var isFirst: Bool { currentIndex == 0 }
    private var completedSets: Int { sets[currentIndex].filter { $0.completed }.count }

    var body: some View {
        ZStack {
            Color(hex: "#F7F5F2").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top bar
                topBar

                // ── Progress strip
                exerciseProgressStrip
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // ── Exercise hero
                        exerciseHero
                            .padding(.horizontal, 16)

                        // ── Sets tracker
                        setsCard
                            .padding(.horizontal, 16)

                        Spacer().frame(height: 20)
                    }
                }

                // ── Bottom nav
                bottomNav
            }
        }
        .navigationBarHidden(true)
        .alert("Finish Workout?", isPresented: $showFinishAlert) {
            Button("Finish & Save", role: .none) { dismiss() }
            Button("Keep Going", role: .cancel) { }
        } message: {
            Text("Great work! Your session will be logged to today's summary.")
        }
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            Button {
                showFinishAlert = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                    Text("End")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(plan.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                Text("Day \(plan.dayNumber) of \(plan.totalDays)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }

            Spacer()

            // Placeholder to balance HStack
            Text("End")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.clear)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: Exercise Progress Strip

    private var exerciseProgressStrip: some View {
        HStack(spacing: 5) {
            ForEach(Array(plan.exercises.enumerated()), id: \.offset) { i, ex in
                RoundedRectangle(cornerRadius: 99)
                    .fill(i < currentIndex
                          ? Color(hex: "#1C1C1E")
                          : i == currentIndex
                              ? Color(hex: "#C4A97D")
                              : Color(UIColor.systemGroupedBackground))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
    }

    // MARK: Exercise Hero Card

    private var exerciseHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(currentIndex + 1) of \(plan.exercises.count)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.7)
                    .foregroundColor(Color(hex: "#C4A97D"))
                Spacer()
                Label(currentExercise.type == .strength ? "Strength" : "Cardio",
                      systemImage: currentExercise.type == .strength
                        ? "dumbbell.fill" : "figure.run")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }

            Text(currentExercise.name)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(Color(UIColor.label))
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)

            // Target chips
            HStack(spacing: 8) {
                if currentExercise.type == .strength {
                    targetChip(icon: "arrow.clockwise", value: "\(currentExercise.targetSets) sets")
                    targetChip(icon: "repeat",          value: currentExercise.targetReps + " reps")
                    targetChip(icon: "scalemass",       value: currentExercise.targetWeight)
                }
            }
            .padding(.top, 12)

            if !currentExercise.notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#C4A97D"))
                    Text(currentExercise.notes)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 5)
    }

    private func targetChip(icon: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(Color(UIColor.label))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(UIColor.systemGroupedBackground))
        .clipShape(Capsule())
    }

    // MARK: Sets Card

    private var setsCard: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("SET")
                    .frame(width: 36, alignment: .leading)
                Spacer()
                Text("REPS")
                    .frame(width: 72, alignment: .center)
                Text("WEIGHT (kg)")
                    .frame(width: 100, alignment: .center)
                Text("")
                    .frame(width: 36)
            }
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundColor(Color(UIColor.tertiaryLabel))
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 20)

            ForEach(sets[currentIndex].indices, id: \.self) { i in
                SetRow(
                    setNumber: i + 1,
                    entry: $sets[currentIndex][i],
                    targetReps: currentExercise.targetReps,
                    targetWeight: currentExercise.targetWeight
                )
                .padding(.horizontal, 20)
                if i < sets[currentIndex].count - 1 {
                    Divider().padding(.horizontal, 20)
                }
            }

            // Completed sets label
            HStack {
                Text("\(completedSets) of \(sets[currentIndex].count) sets logged")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(completedSets == sets[currentIndex].count
                                     ? Color(hex: "#30D158")
                                     : Color(UIColor.secondaryLabel))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 5)
    }

    // MARK: Bottom Nav

    private var bottomNav: some View {
        HStack(spacing: 12) {
            // Back
            if !isFirst {
                Button {
                    navigate(direction: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                        .frame(width: 52, height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }

            // Next / Finish
            Button {
                if isLast {
                    showFinishAlert = true
                } else {
                    navigate(direction: 1)
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isLast ? "Finish Workout 🏁" : "Next Exercise")
                        .font(.system(size: 15, weight: .bold))
                    if !isLast {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isLast ? Color(hex: "#30D158") : Color(UIColor.label))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: isLast)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            Color(hex: "#F7F5F2")
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: -4)
        )
    }

    private func navigate(direction: Int) {
        withAnimation(.easeInOut(duration: 0.22)) {
            currentIndex = max(0, min(plan.exercises.count - 1, currentIndex + direction))
        }
    }
}

// MARK: Set Row

private struct SetRow: View {
    let setNumber: Int
    @Binding var entry: SetEntry
    let targetReps: String
    let targetWeight: String

    var body: some View {
        HStack(spacing: 0) {
            // Set number
            ZStack {
                Circle()
                    .fill(entry.completed
                          ? Color(hex: "#1C1C1E")
                          : Color(UIColor.systemGroupedBackground))
                    .frame(width: 28, height: 28)
                Text("\(setNumber)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(entry.completed ? .white : Color(UIColor.secondaryLabel))
            }
            .frame(width: 36, alignment: .leading)

            Spacer()

            // Reps field
            fieldBox(
                placeholder: targetReps,
                value: $entry.reps,
                unit: "reps"
            )
            .frame(width: 72)

            // Weight field
            fieldBox(
                placeholder: targetWeight,
                value: $entry.weight,
                unit: "kg"
            )
            .frame(width: 100)

            // Complete button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    entry.completed.toggle()
                }
            } label: {
                Image(systemName: entry.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(entry.completed ? Color(hex: "#30D158") : Color(UIColor.tertiaryLabel))
            }
            .buttonStyle(.plain)
            .frame(width: 36)
        }
        .padding(.vertical, 12)
    }

    private func fieldBox(placeholder: String, value: Binding<String>, unit: String) -> some View {
        VStack(spacing: 2) {
            TextField(placeholder, text: value)
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .padding(.vertical, 6)
                .padding(.horizontal, 6)
                .background(Color(UIColor.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(unit)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(UIColor.tertiaryLabel))
        }
        .padding(.horizontal, 4)
    }
}

// ============================================================
// MARK: - Preview
// ============================================================

#Preview("Workout Tab") {
    WorkoutScreen()
}

#Preview("Active Workout") {
    NavigationStack {
        ActiveWorkoutScreen(plan: .mock)
    }
}

