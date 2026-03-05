//
//  NutritionScreen.swift
//  Formé
//
//  Created by Sean Hughes on 3/3/26.
//

import Foundation
import SwiftUI

// ============================================================
// MARK: - Calorie Ring Card
// ============================================================

struct CalorieRingCard: View {

    var goal: Int    = 2200
    var eaten: Int   = 1840
    var protein: (current: Double, goal: Double) = (118, 150)
    var carbs:   (current: Double, goal: Double) = (195, 220)
    var fat:     (current: Double, goal: Double) = (61,  70)

    var left: Int    { max(goal - eaten, 0) }
    var over: Int    { max(eaten - goal, 0) }
    var isOver: Bool { eaten > goal }

    @State private var ringProgress: CGFloat = 0
    @State private var showingMealSheet: Bool = false
    @State private var mealText: String = ""
    @State private var selectedCategory: MealCategory = MealCategory.suggested()

    var body: some View {
        VStack(spacing: 0) {

            // ── Ring + Stats ─────────────────────────────────
            HStack(alignment: .center, spacing: 28) {

                // Ring
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.systemGroupedBackground), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            isOver ? Color(hex: "#FF3B30") : Color(hex: "#C4A97D"),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(
                            color: (isOver ? Color(hex: "#FF3B30") : Color(hex: "#C4A97D")).opacity(0.3),
                            radius: 4
                        )

                    VStack(spacing: 5) {
                        Text("\(Int(min(Double(eaten) / Double(goal), 1.0) * 100))%")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(Color(UIColor.label))
                        Text("of goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
                .frame(width: 104, height: 104)
                .padding(.leading, 20)

                // Stats — left aligned
                VStack(alignment: .leading, spacing: 0) {
                    statRow(label: "Goal",
                            value: goal,
                            color: Color(UIColor.tertiaryLabel))
                    Rectangle()
                        .fill(Color(UIColor.separator).opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.vertical, 5)
                    statRow(label: "Eaten",
                            value: eaten,
                            color: Color(hex: "#C4A97D"))
                    Rectangle()
                        .fill(Color(UIColor.separator).opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.vertical, 5)
                    statRow(label: isOver ? "Over" : "Left",
                            value: isOver ? over : left,
                            color: isOver ? Color(hex: "#FF3B30") : Color(hex: "#30D158"))
                }
                .padding(.trailing, 20)
            }
            .padding(.vertical, 22)

            // ── Divider ──────────────────────────────────────
            Rectangle()
                .fill(Color(UIColor.separator).opacity(0.3))
                .frame(height: 0.5)
                .padding(.horizontal, 20)

            // ── Macros ───────────────────────────────────────
            HStack(spacing: 12) {
                MacroBar(label: "Protein",
                         current: protein.current, goal: protein.goal,
                         color: Color(hex: "#FF6B6B"))
                MacroBar(label: "Carbs",
                         current: carbs.current,   goal: carbs.goal,
                         color: Color(hex: "#FFB347"))
                MacroBar(label: "Fat",
                         current: fat.current,     goal: fat.goal,
                         color: Color(hex: "#4FC3F7"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)

            // ── Water Intake ───────────────────────────────
            WaterIntakeRow(current: 48, goal: 96)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            // ── Log Meal ───────────────────────────────────
            LogMealRow(action: { showingMealSheet = true })
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2,  x: 0, y: 1)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.72).delay(0.1)) {
                ringProgress = min(CGFloat(eaten) / CGFloat(goal), 1.0)
            }
        }
        .sheet(isPresented: $showingMealSheet) {
            MealLogSheet(mealText: $mealText,
                         selectedCategory: $selectedCategory,
                         onSave: {
                             // TODO: integrate save with model; update ring/macros
                             showingMealSheet = false
                             mealText = ""
                             selectedCategory = MealCategory.suggested()
                         },
                         onCancel: {
                             showingMealSheet = false
                         })
        }
    }

    // MARK: - Stat Row (right-aligned)

    private func statRow(label: String, value: Int, color: Color) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // Color accent bar on the LEFT of each stat
            RoundedRectangle(cornerRadius: 99)
                .fill(color)
                .frame(width: 3, height: 32)

            // Label + value, leading aligned
            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(value)")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Color(UIColor.label))
                    Text("kcal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
            }
        }
    }
}

// ============================================================
// MARK: - Macro Bar
// ============================================================

private struct MacroBar: View {
    let label: String
    let current: Double
    let goal: Double
    let color: Color

    @State private var filled: CGFloat = 0
    private var pct: CGFloat { min(CGFloat(current / goal), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .lastTextBaseline) {
                Text(String(format: "%.0fg", current))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.systemGroupedBackground))
                        .frame(height: 5)
                    Capsule()
                        .fill(color)
                        .frame(width: filled * geo.size.width, height: 5)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.65).delay(0.15),
                            value: filled
                        )
                }
            }
            .frame(height: 5)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundColor(color.opacity(0.8))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { filled = pct }
        }
    }
}

// ============================================================
// MARK: - Water Intake Row
// ============================================================

private struct WaterIntakeRow: View {
    var current: Double
    var goal: Double

    @State private var filled: CGFloat = 0
    private var pct: CGFloat { min(CGFloat(current / goal), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                // Accent bar to match stat rows
                RoundedRectangle(cornerRadius: 99)
                    .fill(Color(hex: "#4FC3F7"))
                    .frame(width: 3, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("WATER")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(Color(UIColor.secondaryLabel))

                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(String(format: "%.0foz", current))
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(Color(UIColor.label))
                        Text("of \(Int(goal))oz")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer()
                        // Quick add button (visual only)
                        Button {
                            // Hook up to model later
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Add 8oz")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Color(UIColor.systemBackground))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(hex: "#4FC3F7"))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.systemGroupedBackground))
                        .frame(height: 6)
                    Capsule()
                        .fill(Color(hex: "#4FC3F7"))
                        .frame(width: filled * geo.size.width, height: 6)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.65).delay(0.1),
                            value: filled
                        )
                }
            }
            .frame(height: 6)
        }
        .onAppear { filled = pct }
    }
}

// ============================================================
// MARK: - Meal Logging
// ============================================================

private enum MealCategory: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    static func suggested(date: Date = Date()) -> MealCategory {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }
}

private struct LogMealRow: View {
    var action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left accent to match sections
            RoundedRectangle(cornerRadius: 99)
                .fill(Color(hex: "#C4A97D"))
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("LOG MEAL")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(Color(UIColor.secondaryLabel))
                Text("Add breakfast, lunch, dinner, or a snack")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            Spacer()
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                    Text("Log Meal")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color(UIColor.systemBackground))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(hex: "#C4A97D"))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MealLogSheet: View {
    @Binding var mealText: String
    @Binding var selectedCategory: MealCategory
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Category selector with sensible default and easy override
                Picker("Category", selection: $selectedCategory) {
                    ForEach(MealCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                .pickerStyle(.segmented)

                // Text entry for now; future: photo/voice
                VStack(alignment: .leading, spacing: 8) {
                    Text("What did you eat?")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    TextField("e.g. Grilled chicken salad, 450 kcal", text: $mealText)
                        .textFieldStyle(.roundedBorder)
                }

                // Future extensibility placeholders
                VStack(alignment: .leading, spacing: 10) {
                    Text("Coming soon")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(UIColor.tertiaryLabel))
                    HStack(spacing: 10) {
                        Label("Photo", systemImage: "camera")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(8)
                            .background(Color(UIColor.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Label("Voice", systemImage: "mic")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(8)
                            .background(Color(UIColor.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .foregroundColor(Color(UIColor.secondaryLabel))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(mealText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// ============================================================
// MARK: - Meals List Card
// ============================================================

private struct MealEntry: Identifiable {
    let id = UUID()
    let category: MealCategory
    let title: String
    let calories: Int
}

private struct MealsCard: View {
    var entries: [MealEntry]

    private var grouped: [(MealCategory, [MealEntry])] {
        let groups = Dictionary(grouping: entries, by: { $0.category })
        // Order categories Breakfast, Lunch, Dinner, Snack
        return MealCategory.allCases.compactMap { cat in
            if let items = groups[cat], !items.isEmpty { return (cat, items) }
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 0) {
                Text("Meals")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 99)
                        .fill(Color(hex: "#C4A97D"))
                        .frame(width: 24, height: 1.5)
                    Rectangle()
                        .fill(Color(UIColor.separator).opacity(0.25))
                        .frame(height: 0.75)
                        .padding(.leading, 6)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ForEach(Array(grouped.enumerated()), id: \.offset) { index, pair in
                let (category, items) = pair
                // Section header
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 99)
                        .fill(Color(UIColor.tertiaryLabel))
                        .frame(width: 3, height: 20)
                    Text(category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, index == 0 ? 6 : 14)
                .padding(.bottom, 6)

                // Items
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "fork.knife")
                                .foregroundColor(Color(hex: "#C4A97D"))
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(UIColor.label))
                                Text("\(item.calories) kcal")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                        if item.id != items.last?.id {
                            Rectangle()
                                .fill(Color(UIColor.separator).opacity(0.15))
                                .frame(height: 0.5)
                                .padding(.leading, 54)
                                .padding(.trailing, 20)
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2,  x: 0, y: 1)
    }
}

// ============================================================
// MARK: - Nutrition Screen (composed)
// ============================================================

public struct NutritionScreen: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color(hex: "#F7F5F2").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Nutrition")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(Color(UIColor.label))
                        Text(Date.now.formatted(date: .abbreviated, time: .omitted).uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.4)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .padding(.top, 6)
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
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    // Main cards
                    CalorieRingCard()
                        .padding(.horizontal, 16)

                    MealsCard(entries: [
                        // TODO: replace with real data from your model
                        MealEntry(category: .breakfast, title: "Oatmeal with berries", calories: 320),
                        MealEntry(category: .lunch, title: "Grilled chicken salad", calories: 450),
                        MealEntry(category: .snack, title: "Greek yogurt", calories: 150),
                        MealEntry(category: .dinner, title: "Salmon, rice, broccoli", calories: 620)
                    ])
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                }
                .padding(.bottom, 24)
                
            }
            .scrollIndicators(.hidden)
        }
    }
    
    // Compute a safe top padding based on the device’s safe area
   
}

// ============================================================
// MARK: - Preview
// ============================================================

#Preview {
    ZStack {
        Color(hex: "#F7F5F2").ignoresSafeArea()

        VStack(alignment: .leading, spacing: 0) {

            // Header — matches other screens exactly
            VStack(alignment: .leading, spacing: 0) {
                Text("Nutrition")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(UIColor.label))
                Text("Tuesday, March 3".uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .padding(.top, 6)
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
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)

            CalorieRingCard()
                .padding(.horizontal, 16)

            MealsCard(entries: [
                MealEntry(category: .breakfast, title: "Oatmeal with berries", calories: 320),
                MealEntry(category: .lunch, title: "Grilled chicken salad", calories: 450),
                MealEntry(category: .snack, title: "Greek yogurt", calories: 150),
                MealEntry(category: .dinner, title: "Salmon, rice, broccoli", calories: 620)
            ])
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Spacer()
        }
    }
}

