//
//  Home.swift
//  Formé
//
//  Created by Sean Hughes on 3/3/26.
//

import SwiftUI

// ============================================================
// MARK: - Shared Sub-Views
// ============================================================

private struct SectionLabel: View {
    let title: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundColor(Color(UIColor.secondaryLabel))
            Spacer()
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#C4A97D"))
                }
            }
        }
    }
}

private struct LegendRow: View {
    let label: String
    let value: Int
    let color: Color
    var muted: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7)
            HStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(muted ? Color(UIColor.tertiaryLabel) : .secondary)
                Text("\(value)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(muted ? Color(UIColor.tertiaryLabel) : Color(UIColor.label))
                Text("kcal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(muted ? Color(UIColor.tertiaryLabel) : .secondary)
            }
        }
    }
}

// ============================================================
// MARK: - Greeting Helpers
// ============================================================

private func timeGreeting() -> (text: String, emoji: String) {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12:  return ("Good morning", "👋")
    case 12..<17: return ("Good afternoon", "☀️")
    case 17..<21: return ("Good evening", "🌆")
    default:      return ("Good night", "🌙")
    }
}

private func fullFormattedDate() -> String {
    let f = DateFormatter()
    f.dateFormat = "EEEE, MMMM d"
    return f.string(from: Date())
}

// ============================================================
// MARK: - Header View
// ============================================================

private struct HomeHeaderView: View {
    var userName: String
    @State private var appeared = false
    private let greeting = timeGreeting()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Serif greeting
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting.text + ",")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(UIColor.label))

                HStack(alignment: .center, spacing: 8) {
                    Text(userName)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(Color(UIColor.label))
                    Text(greeting.emoji)
                        .font(.system(size: 26))
                        .rotationEffect(.degrees(appeared ? 0 : -22), anchor: .bottom)
                        .animation(
                            .interpolatingSpring(stiffness: 160, damping: 7).delay(0.4),
                            value: appeared
                        )
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.easeOut(duration: 0.4), value: appeared)

            // Date — small caps
            Text(fullFormattedDate().uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.4)
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .padding(.top, 8)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.12), value: appeared)

            // Luxury gold divider
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 99)
                    .fill(Color(hex: "#C4A97D"))
                    .frame(width: appeared ? 32 : 0, height: 1.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.25), value: appeared)
                Rectangle()
                    .fill(Color(UIColor.separator).opacity(0.25))
                    .frame(height: 0.75)
                    .padding(.leading, 6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
            }
            .padding(.top, 14)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
    }
}

// ============================================================
// MARK: - Summary Card
// ============================================================

enum SummaryTab: String, CaseIterable {
    case energy   = "⚡ Energy"
    case workouts = "🏋️ Workouts"
}

struct SummaryCard: View {
    var data: SummaryData = DashboardMock.summary
    var onDismiss: (() -> Void)? = nil

    @State private var activeTab: SummaryTab = .energy
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            cardHeader
            tabPicker
                .padding(.horizontal, 20)
                .padding(.top, 12)

            if activeTab == .energy {
                energyTabContent
            } else {
                workoutsTabContent
            }

            footerCTA
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 18)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
    }

    private var cardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(0.9)
                Text(data.date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color(UIColor.systemGroupedBackground))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var tabPicker: some View {
        HStack(spacing: 6) {
            ForEach(SummaryTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(activeTab == tab ? Color(UIColor.label) : Color(UIColor.systemGroupedBackground))
                        .foregroundColor(activeTab == tab ? Color(UIColor.systemBackground) : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
        }
    }

    // Energy tab
    private var energyTabContent: some View {
        VStack(spacing: 0) {
            EnergyRingView(calories: data.calories)
                .padding(.horizontal, 20)
                .padding(.top, 16)
            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            VStack(alignment: .leading, spacing: 10) {
                Text("MACROS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                HStack(spacing: 14) {
                    MacroBarView(label: "Protein",
                                 macro: data.macros.protein,
                                 barColor: Color(hex: "#FF6B6B"))
                    MacroBarView(label: "Carbs",
                                 macro: data.macros.carbs,
                                 barColor: Color(hex: "#FFB347"))
                    MacroBarView(label: "Fat",
                                 macro: data.macros.fat,
                                 barColor: Color(hex: "#4FC3F7"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    // Workouts tab
    private var workoutsTabContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SESSIONS · \(data.workouts.count) LOGGED")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.0)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 2)

            ForEach(Array(data.workouts.enumerated()), id: \.element.id) { index, workout in
                WorkoutRowView(workout: workout, delay: Double(index) * 0.07)
                    .padding(.horizontal, 20)
            }

            HStack {
                Text("Total burned")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(data.workouts.reduce(0) { $0 + $1.kcal }) kcal")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color(hex: "#FF6B6B"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 2)
        }
    }

    private var footerCTA: some View {
        Button { } label: {
            Text(activeTab == .energy ? "Log a Meal →" : "Log a Workout →")
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(UIColor.label))
                .foregroundColor(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// ============================================================
// MARK: - Energy Ring View
// ============================================================

private struct EnergyRingView: View {
    let calories: CalorieData
    @State private var burnedProgress: CGFloat = 0
    @State private var netProgress: CGFloat    = 0
    private let ringWidth: CGFloat = 8
    private let size: CGFloat      = 100

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                let innerSize = size - (ringWidth + 4) * 2

                Circle()
                    .stroke(Color(UIColor.systemGroupedBackground), lineWidth: ringWidth)
                    .frame(width: size, height: size)

                Circle()
                    .trim(from: 0, to: burnedProgress)
                    .stroke(Color(hex: "#FF6B6B"),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: "#FF6B6B").opacity(0.35), radius: 4)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: burnedProgress)

                Circle()
                    .stroke(Color(UIColor.systemGroupedBackground), lineWidth: ringWidth)
                    .frame(width: innerSize, height: innerSize)

                Circle()
                    .trim(from: 0, to: netProgress)
                    .stroke(calories.isOverGoal ? Color(hex: "#FF3B30") : Color(hex: "#30D158"),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .frame(width: innerSize, height: innerSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: "#30D158").opacity(0.3), radius: 4)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1), value: netProgress)

                VStack(spacing: 1) {
                    Text("NET")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(calories.net)")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(Color(UIColor.label))
                    Text("kcal")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: size, height: size)

            VStack(alignment: .leading, spacing: 9) {
                LegendRow(label: "Consumed", value: calories.consumed, color: Color(hex: "#30D158"))
                LegendRow(label: "Burned",   value: calories.burned,   color: Color(hex: "#FF6B6B"))
                LegendRow(
                    label: calories.isOverGoal ? "Over goal" : "Remaining",
                    value: abs(calories.remaining),
                    color: calories.isOverGoal ? Color(hex: "#FF3B30") : .secondary,
                    muted: !calories.isOverGoal
                )
            }
        }
        .onAppear {
            let bp = min(CGFloat(calories.burned) / CGFloat(calories.goal), 1.0)
            let np = min(CGFloat(calories.net)    / CGFloat(calories.goal), 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                burnedProgress = bp
                netProgress    = np
            }
        }
    }
}

// ============================================================
// MARK: - Macro Bar View
// ============================================================

private struct MacroBarView: View {
    let label: String
    let macro: MacroData
    let barColor: Color
    @State private var barWidth: CGFloat = 0
    private let pct: CGFloat

    init(label: String, macro: MacroData, barColor: Color) {
        self.label = label
        self.macro = macro
        self.barColor = barColor
        self.pct   = min(CGFloat(macro.grams) / CGFloat(macro.goal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline) {
                Text("\(macro.grams)g")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.systemGroupedBackground)).frame(height: 4)
                    Capsule().fill(barColor)
                        .frame(width: barWidth * geo.size.width, height: 4)
                        .animation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.12), value: barWidth)
                }
            }
            .frame(height: 4)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(0.5)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { barWidth = pct }
        }
    }
}

// ============================================================
// MARK: - Workout Row View
// ============================================================

private struct WorkoutRowView: View {
    let workout: WorkoutEntry
    let delay: Double
    @State private var visible = false

    var body: some View {
        HStack(spacing: 12) {
            Text(workout.emoji)
                .font(.system(size: 17))
                .frame(width: 36, height: 36)
                .background(Color(hex: workout.bgHex))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(workout.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.label))
            Spacer()
            HStack(spacing: 2) {
                Text("−\(workout.kcal)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: workout.colorHex))
                Text("kcal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { Divider() }
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : 10)
        .animation(.easeOut(duration: 0.32).delay(delay), value: visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08 + delay) { visible = true }
        }
    }
}

// ============================================================
// MARK: - Workout Plan Card
// ============================================================

struct WorkoutPlanCard: View {
    var plan: WorkoutPlan = DashboardMock.plan
    var onStart: (() -> Void)? = nil

    @State private var appeared = false
    @State private var buttonPressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Top content
            VStack(alignment: .leading, spacing: 0) {

                // Badge + category
                HStack {
                    Text("DAY \(plan.dayNumber) OF \(plan.totalDays)")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.7)
                        .foregroundColor(Color(hex: "#C0703A"))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#FFF0E8"))
                        .clipShape(Capsule())
                    Spacer()
                    Text(plan.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.35), value: appeared)

                // Workout name — serif
                Text(plan.workoutName)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundColor(Color(UIColor.label))
                    .padding(.top, 12)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.38).delay(0.06), value: appeared)

                // Meta
                HStack(spacing: 5) {
                    Text("~\(plan.durationMinutes) min")
                    Text("·").foregroundColor(Color(UIColor.tertiaryLabel))
                    Text(plan.type)
                    Text("·").foregroundColor(Color(UIColor.tertiaryLabel))
                    Text(plan.difficulty)
                }
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.top, 5)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.38).delay(0.1), value: appeared)

                // Exercise chips
                exerciseChips
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
            }
            .padding(20)

            // Divider
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.3))
                .frame(height: 0.5)

            // Footer
            HStack {
                Group {
                    Text("Est. ")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    + Text("\(plan.estimatedKcal) kcal")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(UIColor.label))
                    + Text(" burned")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .font(.system(size: 13, weight: .regular))

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) { buttonPressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation { buttonPressed = false }
                        onStart?()
                    }
                } label: {
                    Text("Start Workout")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                        .background(Color(UIColor.label))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .scaleEffect(buttonPressed ? 0.94 : 1.0)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.38).delay(0.2), value: appeared)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { appeared = true }
        }
    }

    private var exerciseChips: some View {
        let rows = stride(from: 0, to: plan.exercises.count, by: 2).map {
            Array(plan.exercises[$0..<min($0 + 2, plan.exercises.count)])
        }
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { exercise in
                        Text(exercise)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(UIColor.label))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(UIColor.systemGroupedBackground))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// ============================================================
// MARK: - Home Screen  ← the one view to add to your tab bar
// ============================================================

struct HomeScreen: View {
    @AppStorage("user_name") private var userName: String = "Alex"
    @AppStorage("calorie_goal") private var calorieGoal: Int = 2200
    @AppStorage("protein_goal") private var proteinGoal: Int = 150
    @AppStorage("carbs_goal") private var carbsGoal: Int = 220
    @AppStorage("fat_goal") private var fatGoal: Int = 70

    // Keep using mock intake/burn/grams for now; goals come from AppStorage
    private var summaryData: SummaryData {
        let base = DashboardMock.summary
        return SummaryData(
            label: base.label,
            date: base.date,
            calories: CalorieData(
                consumed: base.calories.consumed,
                burned: base.calories.burned,
                goal: calorieGoal
            ),
            macros: MacrosData(
                protein: MacroData(
                    grams: base.macros.protein.grams,
                    goal: proteinGoal
                ),
                carbs: MacroData(
                    grams: base.macros.carbs.grams,
                    goal: carbsGoal
                ),
                fat: MacroData(
                    grams: base.macros.fat.grams,
                    goal: fatGoal
                )
            ),
            workouts: base.workouts
        )
    }

    private var workoutPlan: WorkoutPlan = DashboardMock.plan

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── Header ────────────────────────────────────
                HomeHeaderView(userName: userName)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)       // NavigationStack adds its own top space
                    .padding(.bottom, 20)

                // ── Energy / Nutrition card ───────────────────
                SectionLabel(title: "Today's Energy", actionLabel: "View all") { }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                SummaryCard(data: summaryData)
                    .padding(.horizontal, 16)

                // ── Workout plan card ─────────────────────────
                SectionLabel(title: "Today's Training")
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 10)

                WorkoutPlanCard(plan: workoutPlan, onStart: {
                    // TODO: push to active workout screen
                })
                .padding(.horizontal, 16)

                // Bottom safe-zone padding
                Spacer().frame(height: 28)
            }
        }
        .background(Color(hex: "#F7F5F2").ignoresSafeArea())
        .navigationTitle("")                // keeps nav bar clean if embedded
        .navigationBarHidden(true)
    }
}

// ============================================================
// MARK: - Preview
// ============================================================

#Preview {
    HomeScreen()
}
