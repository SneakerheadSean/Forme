//
//  NutritionScreen.swift
//  Formé
//
//  Real meal logging backed by Supabase. Today's entries + totals come from
//  NutritionStore; calorie/macro goals come from the user's profile (SessionStore).
//

import SwiftUI

// MARK: - Meal Type (raw values match the meal_entries.meal_type DB check)

enum MealType: String, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack

    var id: String { rawValue }

    var display: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch:     return "Lunch"
        case .dinner:    return "Dinner"
        case .snack:     return "Snacks"
        }
    }

    var emoji: String {
        switch self {
        case .breakfast: return "🥣"
        case .lunch:     return "🥗"
        case .dinner:    return "🍽️"
        case .snack:     return "🍎"
        }
    }
}

// MARK: - Nutrition Screen

struct NutritionScreen: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var nutrition: NutritionStore
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var subscriptions: SubscriptionStore

    @State private var showAdd = false

    private let gold = Color(hex: "C4A97D")

    private var eaten: Int { nutrition.consumedCalories }
    private var goal: Int { session.calorieGoal }
    private var remaining: Int { goal - eaten }
    private var pct: CGFloat { goal > 0 ? min(CGFloat(eaten) / CGFloat(goal), 1) : 0 }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isPro {
                    loggingContent
                } else {
                    ProLockedScreen(
                        icon: "fork.knife",
                        title: "Meal Logging is Pro",
                        message: "Track your food, calories, and macros every day with Forme Pro."
                    )
                }
            }
            .background(Color(hex: "F7F5F2").ignoresSafeArea())
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if subscriptions.isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showAdd = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(gold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                QuickAddMealSheet { name, cals, p, c, f, type in
                    await nutrition.quickAdd(name: name, calories: cals, protein: p, carbs: c, fat: f, mealType: type)
                }
            }
            .task(id: subscriptions.isPro) {
                if subscriptions.isPro, let uid = authService.currentUserId { await nutrition.load(userId: uid) }
            }
            .refreshable {
                if let uid = authService.currentUserId { await nutrition.load(userId: uid) }
            }
        }
    }

    private var loggingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                sectionLabel("TODAY'S ENERGY")
                    .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 10)

                summaryCard
                    .padding(.horizontal, 16)

                sectionLabel("RECENT MEALS")
                    .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 10)

                if nutrition.entries.isEmpty {
                    emptyState.padding(.horizontal, 16)
                } else {
                    mealsCard.padding(.horizontal, 16)
                }

                Spacer().frame(height: 28)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t)
            .font(.system(size: 11, weight: .bold)).tracking(1.4)
            .foregroundColor(Color(UIColor.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Summary Card

    private var summaryCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle().stroke(Color(UIColor.systemGroupedBackground), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    Circle().trim(from: 0, to: pct)
                        .stroke(remaining < 0 ? Color(hex: "FF3B30") : gold,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 100, height: 100)
                        .animation(.spring(response: 0.8, dampingFraction: 0.85), value: pct)
                    VStack(spacing: 1) {
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 18, weight: .heavy)).foregroundColor(Color(UIColor.label))
                        Text("of goal")
                            .font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 12)

                VStack(alignment: .leading, spacing: 8) {
                    summaryLine("GOAL", "\(goal) kcal", Color(UIColor.label))
                    summaryLine("EATEN", "\(eaten) kcal", Color(UIColor.label))
                    summaryLine(remaining < 0 ? "OVER" : "REMAINING",
                                "\(abs(remaining)) kcal",
                                remaining < 0 ? Color(hex: "FF3B30") : Color(hex: "30D158"))
                }
            }
            .padding(.horizontal, 20).padding(.top, 16)

            Divider().padding(.horizontal, 20).padding(.top, 14)

            VStack(alignment: .leading, spacing: 10) {
                Text("MACROS")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.secondary).tracking(1.0)
                HStack(spacing: 14) {
                    MacroBar(title: "PROTEIN", grams: nutrition.proteinG, goal: session.proteinGoal, color: Color(hex: "FF6B6B"))
                    MacroBar(title: "CARBS",   grams: nutrition.carbsG,   goal: session.carbsGoal,   color: Color(hex: "FFB347"))
                    MacroBar(title: "FAT",     grams: nutrition.fatG,     goal: session.fatGoal,     color: Color(hex: "4FC3F7"))
                }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 18)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
    }

    private func summaryLine(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.secondary).tracking(0.8)
            Spacer()
            Text(value).font(.system(size: 14, weight: .heavy)).foregroundColor(color)
        }
    }

    // MARK: Meals Card

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(MealType.allCases.enumerated()), id: \.element.id) { idx, type in
                let items = nutrition.entries(for: type)
                if !items.isEmpty {
                    HStack {
                        Text(type.display.uppercased())
                            .font(.system(size: 10, weight: .bold)).tracking(1.0)
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                        Spacer()
                        Text("\(items.reduce(0) { $0 + Int($1.calories) }) kcal")
                            .font(.system(size: 10, weight: .bold)).foregroundColor(Color(UIColor.tertiaryLabel))
                    }
                    .padding(.top, idx == 0 ? 16 : 14).padding(.bottom, 4).padding(.horizontal, 20)

                    ForEach(items) { entry in
                        mealRow(entry, emoji: type.emoji)
                        if entry.id != items.last?.id {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
            }
            Color.clear.frame(height: 10)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
    }

    private func mealRow(_ entry: MealEntryRow, emoji: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 17))
                .frame(width: 36, height: 36)
                .background(Color(UIColor.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(Color(UIColor.label))
                Text("\(Int(entry.calories)) kcal")
                    .font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
            }
            Spacer()
            Button {
                Task { await nutrition.delete(entry) }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .frame(width: 32, height: 32)
                    .background(Color(UIColor.systemGroupedBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10).padding(.horizontal, 20)
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife").font(.system(size: 30)).foregroundColor(gold)
            Text("No meals logged yet")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(UIColor.label))
            Text("Tap + to log your first meal of the day.")
                .font(.system(size: 13)).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button { showAdd = true } label: {
                Text("Log a Meal")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color(UIColor.label)).clipShape(Capsule())
            }
            .buttonStyle(.plain).padding(.top, 4)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
    }
}

// MARK: - Macro Bar

private struct MacroBar: View {
    let title: String
    let grams: Int
    let goal: Int
    let color: Color

    private var pct: CGFloat { goal > 0 ? min(CGFloat(grams) / CGFloat(goal), 1) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline) {
                Text("\(grams)g").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(UIColor.label))
                Spacer()
                Text("\(Int(pct * 100))%").font(.system(size: 10, weight: .medium)).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.systemGroupedBackground)).frame(height: 4)
                    Capsule().fill(color).frame(width: geo.size.width * pct, height: 4)
                }
            }
            .frame(height: 4)
            Text(title).font(.system(size: 9, weight: .medium)).foregroundColor(.secondary).tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Add Meal Sheet

struct QuickAddMealSheet: View {
    /// (name, calories, protein, carbs, fat, mealType)
    var onSave: (String, Int, Int, Int, Int, MealType) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var mealType: MealType = .breakfast
    @State private var saving = false

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Int(calories) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    field("MEAL NAME") {
                        TextField("e.g. Chicken & rice", text: $name)
                            .textInputAutocapitalization(.words)
                    }
                    field("CALORIES") {
                        TextField("kcal", text: $calories).keyboardType(.numberPad)
                    }
                    HStack(spacing: 12) {
                        field("PROTEIN (g)") { TextField("0", text: $protein).keyboardType(.numberPad) }
                        field("CARBS (g)")   { TextField("0", text: $carbs).keyboardType(.numberPad) }
                        field("FAT (g)")     { TextField("0", text: $fat).keyboardType(.numberPad) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEAL TYPE")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.secondary).tracking(0.8)
                        Picker("Type", selection: $mealType) {
                            ForEach(MealType.allCases) { Text($0.display).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "F7F5F2").ignoresSafeArea())
            .navigationTitle("Log a Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saving = true
                        Task {
                            await onSave(
                                name.trimmingCharacters(in: .whitespaces),
                                Int(calories) ?? 0, Int(protein) ?? 0,
                                Int(carbs) ?? 0, Int(fat) ?? 0, mealType
                            )
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
        .presentationDetents([.medium, .large])
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
    NutritionScreen()
        .environmentObject(SessionStore())
        .environmentObject(NutritionStore())
        .environmentObject(AuthService.shared)
}
