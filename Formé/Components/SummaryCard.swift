//
//  SummaryCard.swift
//  Formé
//
//  Created by Sean Hughes on 3/3/26.
//

import SwiftUI

// MARK: - Models

struct CalorieData {
    var consumed: Int
    var burned: Int
    var goal: Int

    var net: Int { consumed - burned }
    var remaining: Int { goal - net }
    var isOverGoal: Bool { net > goal }
}

struct MacroData {
    var grams: Int
    var goal: Int
    var color: Color
}

struct MacrosData {
    var protein: MacroData
    var carbs: MacroData
    var fat: MacroData
}

struct WorkoutEntry: Identifiable {
    let id: Int
    let name: String
    let kcal: Int
    let emoji: String
    let color: Color
    let bgColor: Color
}

struct SummaryData {
    var label: String
    var date: String
    var calories: CalorieData
    var macros: MacrosData
    var workouts: [WorkoutEntry]
}

// MARK: - Mock Data

extension SummaryData {
    static let mock = SummaryData(
        label: "TODAY'S SUMMARY",
        date: {
            let f = DateFormatter()
            f.dateFormat = "EEEE, MMM d"
            return f.string(from: Date())
        }(),
        calories: CalorieData(consumed: 1840, burned: 635, goal: 2200),
        macros: MacrosData(
            protein: MacroData(grams: 118, goal: 150, color: Color(hex: "#FF6B6B")),
            carbs:   MacroData(grams: 195, goal: 220, color: Color(hex: "#FFB347")),
            fat:     MacroData(grams: 61,  goal: 70,  color: Color(hex: "#4FC3F7"))
        ),
        workouts: [
            WorkoutEntry(id: 1, name: "Morning Run", kcal: 312, emoji: "🏃",
                         color: Color(hex: "#FF6B6B"), bgColor: Color(hex: "#FFF0F0")),
            WorkoutEntry(id: 2, name: "Upper Body",  kcal: 228, emoji: "💪",
                         color: Color(hex: "#FFB347"), bgColor: Color(hex: "#FFF8EE")),
            WorkoutEntry(id: 3, name: "Yoga Flow",   kcal: 95,  emoji: "🧘",
                         color: Color(hex: "#A78BFA"), bgColor: Color(hex: "#F5F0FF")),
        ]
    )
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Tab Enum

enum SummaryTab: String, CaseIterable {
    case energy   = "⚡ Energy"
    case workouts = "🏋️ Workouts"
}

// MARK: - Main Card View

struct SummaryCard: View {
    var data: SummaryData = .mock
    var onDismiss: (() -> Void)? = nil

    @State private var activeTab: SummaryTab = .energy
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                cardContent
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .scaleEffect(appeared ? 1 : 0.98)
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: appeared)

                Text("Showing mock data · Wire up your data source to go live")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 14)
            }
            .padding(24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                appeared = true
            }
        }
    }

    // MARK: Card Shell

    private var cardContent: some View {
        VStack(spacing: 0) {
            cardHeader
            tabPicker
                .padding(.horizontal, 20)
                .padding(.top, 14)

            if activeTab == .energy {
                energyTabContent
            } else {
                workoutsTabContent
            }

            footerCTA
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 8)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
    }

    // MARK: Header

    private var cardHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(data.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                Text(data.date)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            Spacer()
            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.systemGroupedBackground))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    // MARK: Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 6) {
            ForEach(SummaryTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(activeTab == tab ? Color(UIColor.label) : Color(UIColor.systemGroupedBackground))
                        .foregroundColor(activeTab == tab ? Color(UIColor.systemBackground) : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    // MARK: Energy Tab

    private var energyTabContent: some View {
        VStack(spacing: 0) {
            EnergyRingView(calories: data.calories)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Divider()
                .padding(.horizontal, 20)
                .padding(.vertical, 18)

            VStack(alignment: .leading, spacing: 12) {
                Text("MACROS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)

                HStack(spacing: 16) {
                    MacroBarView(label: "Protein", macro: data.macros.protein)
                    MacroBarView(label: "Carbs",   macro: data.macros.carbs)
                    MacroBarView(label: "Fat",     macro: data.macros.fat)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: Workouts Tab

    private var workoutsTabContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SESSIONS · \(data.workouts.count) LOGGED")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1.0)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)

            ForEach(Array(data.workouts.enumerated()), id: \.element.id) { index, workout in
                WorkoutRowView(workout: workout, delay: Double(index) * 0.08)
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
            .padding(.top, 14)
            .padding(.bottom, 4)
        }
    }

    // MARK: Footer CTA

    private var footerCTA: some View {
        Button {
            // TODO: Navigate to log meal or workout
        } label: {
            Text(activeTab == .energy ? "Log a Meal →" : "Log a Workout →")
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color(UIColor.label))
                .foregroundColor(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Energy Ring View

struct EnergyRingView: View {
    let calories: CalorieData

    @State private var burnedProgress: CGFloat = 0
    @State private var netProgress: CGFloat = 0

    private let ringWidth: CGFloat = 9
    private let size: CGFloat      = 110

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                let innerSize = size - (ringWidth + 4) * 2

                // Outer track
                Circle()
                    .stroke(Color(UIColor.systemGroupedBackground), lineWidth: ringWidth)
                    .frame(width: size, height: size)

                // Outer ring — calories burned
                Circle()
                    .trim(from: 0, to: burnedProgress)
                    .stroke(
                        Color(hex: "#FF6B6B"),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: "#FF6B6B").opacity(0.4), radius: 4)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: burnedProgress)

                // Inner track
                Circle()
                    .stroke(Color(UIColor.systemGroupedBackground), lineWidth: ringWidth)
                    .frame(width: innerSize, height: innerSize)

                // Inner ring — net consumed
                Circle()
                    .trim(from: 0, to: netProgress)
                    .stroke(
                        calories.isOverGoal ? Color(hex: "#FF3B30") : Color(hex: "#30D158"),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .frame(width: innerSize, height: innerSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color(hex: "#30D158").opacity(0.35), radius: 4)
                    .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1), value: netProgress)

                // Center text
                VStack(spacing: 1) {
                    Text("NET")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(calories.net)")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Color(UIColor.label))
                    Text("kcal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: size, height: size)

            // Legend
            VStack(alignment: .leading, spacing: 10) {
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
            let burnedPct = min(CGFloat(calories.burned) / CGFloat(calories.goal), 1.0)
            let netPct    = min(CGFloat(calories.net)    / CGFloat(calories.goal), 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                burnedProgress = burnedPct
                netProgress    = netPct
            }
        }
    }
}

struct LegendRow: View {
    let label: String
    let value: Int
    let color: Color
    var muted: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
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

// MARK: - Macro Bar View

struct MacroBarView: View {
    let label: String
    let macro: MacroData

    @State private var barWidth: CGFloat = 0
    private let pct: CGFloat

    init(label: String, macro: MacroData) {
        self.label = label
        self.macro = macro
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
                    Capsule()
                        .fill(Color(UIColor.systemGroupedBackground))
                        .frame(height: 4)
                    Capsule()
                        .fill(macro.color)
                        .frame(width: barWidth * geo.size.width, height: 4)
                        .animation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.12), value: barWidth)
                }
            }
            .frame(height: 4)

            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(0.5)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                barWidth = pct
            }
        }
    }
}

// MARK: - Workout Row View

struct WorkoutRowView: View {
    let workout: WorkoutEntry
    let delay: Double

    @State private var visible = false

    var body: some View {
        HStack(spacing: 12) {
            Text(workout.emoji)
                .font(.system(size: 18))
                .frame(width: 38, height: 38)
                .background(workout.bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            Text(workout.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(UIColor.label))

            Spacer()

            HStack(spacing: 2) {
                Text("−\(workout.kcal)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(workout.color)
                Text("kcal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : 12)
        .animation(.easeOut(duration: 0.35).delay(delay), value: visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08 + delay) {
                visible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SummaryCard(data: .mock, onDismiss: { print("dismissed") })
}
