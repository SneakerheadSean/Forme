//
//  NutritionScreen.swift
//  Formé
//
//  Created by Sean Hughes on 3/3/26.
//

import SwiftUI

// Local hex initializer to match the rest of the app's usage
fileprivate extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Meal Models
enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snacks    = "Snacks"
    var id: String { rawValue }
}

struct MealEntry: Identifiable {
    let id = UUID()
    var emoji: String
    var name: String
    var kcal: Int
    var type: MealType
}

struct NutritionScreen: View {

    @State private var meals: [MealEntry] = [
        MealEntry(emoji: "🥣", name: "Overnight Oats", kcal: 420, type: .breakfast),
        MealEntry(emoji: "☕️", name: "Latte",           kcal: 120, type: .breakfast),
        MealEntry(emoji: "🥗", name: "Chicken Salad",   kcal: 520, type: .lunch),
        MealEntry(emoji: "🥪", name: "Turkey Sandwich", kcal: 430, type: .lunch),
        MealEntry(emoji: "🍝", name: "Pasta Dinner",    kcal: 780, type: .dinner),
        MealEntry(emoji: "🍫", name: "Dark Chocolate",  kcal: 180, type: .snacks)
    ]
    @State private var editingMeal: MealEntry? = nil
    @State private var showEditor: Bool = false

    private var mealsByType: [(MealType, [MealEntry])] {
        MealType.allCases.map { type in
            (type, meals.filter { $0.type == type })
        }.filter { !$0.1.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Section label
                    Text("TODAY'S ENERGY")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 10)

                    NutritionSummaryCard()
                        .padding(.horizontal, 16)

                    // Recent Meals section placeholder (kept minimal but themed)
                    Text("RECENT MEALS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundColor(Color(UIColor.secondaryLabel))
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 10)

                    RecentMealsCard(groups: mealsByType) { meal in
                        editingMeal = meal
                        showEditor = true
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 28)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(hex: "#F7F5F2").ignoresSafeArea())
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEditor, onDismiss: { editingMeal = nil }) {
                if var meal = editingMeal {
                    MealInlineEditor(meal: meal) { updated in
                        if let idx = meals.firstIndex(where: { $0.id == updated.id }) {
                            meals[idx] = updated
                        }
                        showEditor = false
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .background(Color(hex: "#F7F5F2").ignoresSafeArea())
                }
            }
        }
    }
}

struct NutritionSummaryCard: View {
    private let gold = Color(hex: "#C4A97D")
    private let proteinColor = Color(hex: "#FF6B6B")
    private let carbsColor   = Color(hex: "#FFB347")
    private let fatColor     = Color(hex: "#4FC3F7")

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.9)
                    Text("Energy & Macros")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Rings + summary
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.systemGroupedBackground), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: 0.83)
                        .stroke(gold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                    VStack(spacing: 1) {
                        Text("83%")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(Color(UIColor.label))
                        Text("of goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .leading, spacing: 8) {
                    SummaryLine(title: "GOAL",  value: "2,200 kcal")
                    SummaryLine(title: "EATEN", value: "1,840 kcal")
                    SummaryLine(title: "REMAINING", value: "360 kcal", valueColor: Color(hex: "#30D158"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Divider().padding(.horizontal, 20).padding(.top, 14)

            // Macros
            VStack(alignment: .leading, spacing: 10) {
                Text("MACROS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                HStack(spacing: 14) {
                    MacroBar(title: "PROTEIN", grams: 118, percent: 0.78, color: proteinColor)
                    MacroBar(title: "CARBS",   grams: 195, percent: 0.88, color: carbsColor)
                    MacroBar(title: "FAT",     grams: 61,  percent: 0.87, color: fatColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Divider().padding(.horizontal, 20).padding(.top, 14)

            // Water
            WaterRow()
                .padding(.horizontal, 20)
                .padding(.top, 14)

            // CTA
            Button {
                // log meal action
            } label: {
                Text("Log a Meal →")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(UIColor.label))
                    .foregroundColor(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}

struct SummaryLine: View {
    let title: String
    let value: String
    var valueColor: Color = Color(UIColor.label)

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(0.8)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(valueColor)
        }
    }
}

struct MacroRow: View { // kept for API compatibility if referenced elsewhere
    var body: some View {
        EmptyView()
    }
}

struct MacroBar: View {
    let title: String
    let grams: Int
    let percent: CGFloat
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline) {
                Text("\(grams)g")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Spacer()
                Text("\(Int(percent * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.systemGroupedBackground)).frame(height: 4)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * percent, height: 4)
                }
            }
            .frame(height: 4)
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WaterRow: View {
    private let waterColor = Color(hex: "#4FC3F7")

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WATER")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.8)
                    Text("48oz of 96oz")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Color(UIColor.label))
                }
                Spacer()
                Button {
                    // add 8 oz
                } label: {
                    Text("Add 8oz")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.label))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.systemGroupedBackground))
                    Capsule().fill(waterColor)
                        .frame(width: geo.size.width * 0.5)
                }
            }
            .frame(height: 6)
        }
    }
}

struct RecentMealsCard: View {
    let groups: [(MealType, [MealEntry])]
    let onEdit: (MealEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.9)
                    Text("Recent Meals")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            VStack(spacing: 0) {
                ForEach(Array(groups.enumerated()), id: \.offset) { gi, group in
                    let (type, items) = group
                    // Section header
                    HStack {
                        Text(type.rawValue.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.0)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                        Spacer()
                    }
                    .padding(.top, gi == 0 ? 4 : 12)
                    .padding(.bottom, 2)

                    ForEach(items) { meal in
                        mealRow(meal: meal)
                        if meal.id != items.last?.id {
                            Divider().padding(.leading, 20)
                        }
                    }

                    if gi != groups.count - 1 {
                        Divider().padding(.horizontal, 0).padding(.top, 10)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    private func mealRow(meal: MealEntry) -> some View {
        HStack(spacing: 12) {
            Text(meal.emoji)
                .font(.system(size: 17))
                .frame(width: 36, height: 36)
                .background(Color(UIColor.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(UIColor.label))
                Text("\(meal.kcal) kcal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                onEdit(meal)
            } label: {
                Text("Edit")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(UIColor.label))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color(UIColor.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Inline Meal Editor (sheet)
struct MealInlineEditor: View {
    @State var meal: MealEntry
    var onSave: (MealEntry) -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Emoji & name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEAL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                        HStack(spacing: 10) {
                            TextField("🍽️", text: Binding(
                                get: { meal.emoji },
                                set: { meal.emoji = $0 }
                            ))
                            .font(.system(size: 28))
                            .frame(width: 52, height: 52)
                            .background(Color(UIColor.systemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            TextField("Meal name", text: Binding(
                                get: { meal.name },
                                set: { meal.name = $0 }
                            ))
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal, 12)
                            .frame(height: 52)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                        }
                    }

                    // Calories
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CALORIES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                        TextField("kcal", value: Binding(
                            get: { meal.kcal },
                            set: { meal.kcal = $0 }
                        ), formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .font(.system(size: 17, weight: .semibold))
                        .padding(14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                    }

                    // Meal type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEAL TYPE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(0.8)
                        Picker("Type", selection: Binding(
                            get: { meal.type },
                            set: { meal.type = $0 }
                        )) {
                            ForEach(MealType.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Spacer(minLength: 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(hex: "#F7F5F2").ignoresSafeArea())
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onSave(meal) }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(UIColor.label))
                }
            }
        }
    }
}

#Preview {
    NutritionScreen()
}

