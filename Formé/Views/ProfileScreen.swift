import SwiftUI
import Combine

// MARK: - Color Tokens

private enum Palette {
    // Brand
    static let soleil       = Color(hexString: "FFAA00")
    static let soleilLight  = Color(hexString: "FFC233")
    static let soleilDeep   = Color(hexString: "E09400")
    static let soleilTint   = Color(hexString: "FFAA00").opacity(0.12)

    // Semantic
    static let burn         = Color(hexString: "F04E2A")
    static let burnTint     = Color(hexString: "F04E2A").opacity(0.10)
    static let fuel         = Color(hexString: "F59E0B")
    static let pulse        = Color(hexString: "2563EB")
    static let recover      = Color(hexString: "7C3AED")
    static let formeSuccess = Color(hexString: "16A34A")

    // Surfaces — updated to match system/hex used across Home/Workout screens
    static let bgBase       = Color(hexString: "F7F5F2")
    static let bgCard       = Color.white
    static let bgCardAlt    = Color(UIColor.systemGroupedBackground)
    static let bgInverted   = Color(UIColor.label)

    // Ink - updated to system label colors
    static let ink          = Color(UIColor.label)
    static let inkSecondary = Color(UIColor.secondaryLabel)
    static let inkTertiary  = Color(UIColor.tertiaryLabel)
    static let border       = Color(UIColor.separator).opacity(0.25)
}

// Fallback initialiser (hex string, no #)
fileprivate extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptics

private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

// MARK: - ScrollOffsetPreferenceKey

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Helpers

private func clamp(_ value: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
    if value < minV { return minV }
    if value > maxV { return maxV }
    return value
}

// MARK: - Models

struct UserGoals {
    var calorieTarget: Double = 2200
    var proteinTarget: Double = 150
    var carbTarget: Double = 220
    var fatTarget: Double = 70
    var waterTarget: Double = 96
    var primaryGoal: ProfileFitnessGoal = .muscleGain
    var weeklyWorkouts: Int = 4
}

enum ProfileFitnessGoal: String, CaseIterable, Identifiable {
    case weightLoss   = "Weight Loss"
    case muscleGain   = "Muscle Gain"
    case maintenance  = "Maintenance"
    case performance  = "Performance"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .weightLoss:  return "flame.fill"
        case .muscleGain:  return "bolt.fill"
        case .maintenance: return "equal.circle.fill"
        case .performance: return "figure.run"
        }
    }

    var accentColor: Color {
        switch self {
        case .weightLoss:  return Palette.burn
        case .muscleGain:  return Palette.pulse
        case .maintenance: return Palette.soleil
        case .performance: return Palette.recover
        }
    }
}

// MARK: - View Model

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var goals = UserGoals()
    @Published var name: String = "Alex"
    @Published var unitSystem: UnitSystem = .imperial
    @Published var darkMode: AppearanceMode = .system
    @Published var notificationsEnabled: Bool = true
    @Published var workoutReminders: Bool = true
    @Published var mealReminders: Bool = false
    @Published var healthKitSync: Bool = true
    @Published var feedbackText: String = ""
    @Published var feedbackCategory: FeedbackCategory = .general
    @Published var showFeedbackSuccess: Bool = false
    @Published var isSendingFeedback: Bool = false

    enum UnitSystem: String, CaseIterable {
        case imperial = "Imperial (lbs, oz)"
        case metric   = "Metric (kg, ml)"
    }

    enum AppearanceMode: String, CaseIterable {
        case system = "System"
        case light  = "Light"
        case dark   = "Dark"
    }

    func submitFeedback() {
        guard !feedbackText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        impact(.medium)
        isSendingFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isSendingFeedback = false
            self.showFeedbackSuccess = true
            self.feedbackText = ""
        }
    }
}

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case general     = "General"
    case bug         = "Bug Report"
    case featureReq  = "Feature Request"
    case nutrition   = "Nutrition"
    case training    = "Training"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .general:    return "bubble.left.fill"
        case .bug:        return "ladybug.fill"
        case .featureReq: return "lightbulb.fill"
        case .nutrition:  return "fork.knife"
        case .training:   return "dumbbell.fill"
        }
    }
}

// MARK: - Root ProfileScreen

struct ProfileScreen: View {
    @StateObject private var vm = ProfileViewModel()
    @EnvironmentObject var authService: AuthService
    @State private var showSignOutConfirmation = false
    @State private var activeSheet: ProfileSheet?
    @State private var scrollOffset: CGFloat = 0

    enum ProfileSheet: Identifiable {
        case editGoals, editName, units, appearance, notifications, feedback
        var id: Int { hashValue }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch vm.darkMode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(hexString: "F7F5F2").ignoresSafeArea()

                GeometryReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // ── Collapsing header (now scrolls with content)
                            let collapseRange: CGFloat = 120
                            let progress = clamp((-scrollOffset) / collapseRange, 0, 1)
                            CollapsingProfileHeader(name: vm.name, goal: vm.goals.primaryGoal, progress: progress)
                                .frame(height: 140)
                                .padding(.top, 8)

                            // ── Goals Card
                            SectionCard(label: "GOALS") {
                                GoalsSummaryRow(goals: vm.goals) {
                                    impact()
                                    activeSheet = .editGoals
                                }
                            }

                            // ── App Settings
                            SectionCard(label: "APP SETTINGS") {
                                VStack(spacing: 0) {
                                    SettingsRow(
                                        icon: "scalemass.fill",
                                        iconColor: Palette.pulse,
                                        title: "Units",
                                        detail: vm.unitSystem.rawValue.components(separatedBy: " ").first ?? ""
                                    ) { impact(); activeSheet = .units }

                                    Divider().padding(.leading, 52).foregroundStyle(Color(UIColor.separator).opacity(0.3))

                                    SettingsRow(
                                        icon: "circle.lefthalf.filled",
                                        iconColor: Palette.inkSecondary,
                                        title: "Appearance",
                                        detail: vm.darkMode.rawValue
                                    ) { impact(); activeSheet = .appearance }

                                    Divider().padding(.leading, 52).foregroundStyle(Color(UIColor.separator).opacity(0.3))

                                    SettingsToggleRow(
                                        icon: "heart.fill",
                                        iconColor: Palette.burn,
                                        title: "Health App Sync",
                                        isOn: $vm.healthKitSync
                                    )
                                }
                            }

                            // ── Notifications
                            SectionCard(label: "NOTIFICATIONS") {
                                VStack(spacing: 0) {
                                    SettingsToggleRow(
                                        icon: "bell.fill",
                                        iconColor: Palette.soleil,
                                        title: "Enable Notifications",
                                        isOn: $vm.notificationsEnabled
                                    )
                                    Divider().padding(.leading, 52).foregroundStyle(Color(UIColor.separator).opacity(0.3))
                                    SettingsToggleRow(
                                        icon: "dumbbell.fill",
                                        iconColor: Palette.pulse,
                                        title: "Workout Reminders",
                                        isOn: $vm.workoutReminders
                                    )
                                    .opacity(vm.notificationsEnabled ? 1 : 0.4)
                                    .disabled(!vm.notificationsEnabled)

                                    Divider().padding(.leading, 52).foregroundStyle(Color(UIColor.separator).opacity(0.3))

                                    SettingsToggleRow(
                                        icon: "fork.knife",
                                        iconColor: Palette.fuel,
                                        title: "Meal Reminders",
                                        isOn: $vm.mealReminders
                                    )
                                    .opacity(vm.notificationsEnabled ? 1 : 0.4)
                                    .disabled(!vm.notificationsEnabled)
                                }
                            }

                            // ── Feedback
                            SectionCard(label: "FEEDBACK") {
                                Button {
                                    impact()
                                    activeSheet = .feedback
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Palette.soleilTint)
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Palette.soleil)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Send Feedback")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Palette.ink)
                                            Text("Bug reports, ideas, or just say hi")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Palette.inkTertiary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Palette.inkTertiary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }

                            // ── About & Legal
                            SectionCard(label: "ABOUT") {
                                VStack(spacing: 0) {
                                    AboutRow(title: "Version", detail: "1.0.0 (42)")
                                    Divider().padding(.leading, 16).foregroundStyle(Color(UIColor.separator).opacity(0.3))
                                    AboutRow(title: "Privacy Policy", hasChevron: true) {}
                                    Divider().padding(.leading, 16).foregroundStyle(Color(UIColor.separator).opacity(0.3))
                                    AboutRow(title: "Terms of Service", hasChevron: true) {}
                                    Divider().padding(.leading, 16).foregroundStyle(Color(UIColor.separator).opacity(0.3))
                                    AboutRow(title: "Restore Purchases", hasChevron: true) {}
                                }
                            }

                            // ── Sign Out
                            Button {
                                impact(.heavy)
                                showSignOutConfirmation = true
                            } label: {
                                Text("Sign Out")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Palette.burn)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Palette.burnTint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .confirmationDialog(
                                "Sign Out",
                                isPresented: $showSignOutConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Sign Out", role: .destructive) {
                                    Task { await authService.signOut() }
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("You will need to sign in again to access your account.")
                            }

                            // Bottom safe area pad - reduced from 40 to 28
                            Color.clear.frame(height: 28)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("profileScroll")).minY)
                            }
                        )
                    }
                    .coordinateSpace(name: "profileScroll")
                }
            }
        }
        .preferredColorScheme(resolvedColorScheme)
        // ── Sheets backgrounds updated to F7F5F2
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .editGoals:   EditGoalsSheet(goals: $vm.goals)
            case .editName:    EditNameSheet(name: $vm.name)
            case .units:       UnitsSheet(selection: $vm.unitSystem)
            case .appearance:  AppearanceSheet(selection: $vm.darkMode)
            case .notifications: EmptyView()
            case .feedback:    FeedbackSheet(vm: vm)
            }
        }
        .toast(isPresented: $vm.showFeedbackSuccess, message: "Feedback sent — thank you! 🙌")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}

// MARK: - CollapsingProfileHeader

private struct CollapsingProfileHeader: View {
    let name: String
    let goal: ProfileFitnessGoal
    let progress: CGFloat // 0 = expanded, 1 = collapsed

    var body: some View {
        ZStack {
            // Glow atmosphere (removed ignoresSafeArea on top for harmony)
            RadialGradient(
                colors: [Palette.soleil.opacity(0.18), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 220
            )

            // Large expanded state
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: goal.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(goal.accentColor)
                    Text(goal.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(Palette.inkSecondary)
                }
                .opacity(1 - progress)
                .scaleEffect(1 - progress * 0.15, anchor: .leading)
                .padding(.top, 6)

                Text("Profile")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Palette.ink)
                    .opacity(1 - progress)
                    .scaleEffect(1 - progress * 0.15, anchor: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Collapsed compact state
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Palette.soleilLight, Palette.soleilDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Color(hexString: "141410"))
                }

                VStack(spacing: 0) {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    Text(goal.rawValue.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.4)
                        .foregroundStyle(Palette.inkTertiary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .opacity(progress)
            .scaleEffect(0.85 + (progress * 0.15), anchor: .leading)
        }
    }
}

// MARK: - Goals Summary Row

private struct GoalsSummaryRow: View {
    let goals: UserGoals
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Primary goal badge
                HStack {
                    Label {
                        Text(goals.primaryGoal.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(goals.primaryGoal.accentColor)
                    } icon: {
                        Image(systemName: goals.primaryGoal.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(goals.primaryGoal.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(goals.primaryGoal.accentColor.opacity(0.12),
                                in: Capsule())

                    Spacer()

                    Text("Edit Goals")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.soleil)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.soleil)
                }

                // Macro targets grid
                HStack(spacing: 12) {
                    GoalPill(label: "CALORIES", value: "\(Int(goals.calorieTarget))", unit: "kcal", color: Palette.soleil)
                    GoalPill(label: "PROTEIN",  value: "\(Int(goals.proteinTarget))", unit: "g",    color: Palette.burn)
                    GoalPill(label: "WORKOUTS", value: "\(goals.weeklyWorkouts)",     unit: "/wk",  color: Palette.pulse)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct GoalPill: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Palette.inkTertiary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.inkSecondary)
            }
            Rectangle()
                .fill(color)
                .frame(height: 2)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(UIColor.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Shared Section Card

private struct SectionCard<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Palette.inkSecondary)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(UIColor.systemGroupedBackground))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text(detail)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.inkTertiary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Toggle Row

private struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(UIColor.systemGroupedBackground))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Palette.ink)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Palette.soleil)
                .labelsHidden()
                .onChange(of: isOn) { _ in impact(.light) }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - About Row

private struct AboutRow: View {
    let title: String
    var detail: String = ""
    var hasChevron: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
            if action != nil { impact() }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(hasChevron ? Palette.ink : Palette.ink)
                Spacer()
                if !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Palette.inkTertiary)
                }
                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .disabled(action == nil && !hasChevron)
    }
}

// MARK: - Edit Goals Sheet

struct EditGoalsSheet: View {
    @Binding var goals: UserGoals
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexString: "F7F5F2").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Primary Goal Picker
                        SheetSectionCard(label: "PRIMARY GOAL") {
                            VStack(spacing: 10) {
                                ForEach(ProfileFitnessGoal.allCases) { goal in
                                    GoalOptionRow(
                                        goal: goal,
                                        isSelected: goals.primaryGoal == goal
                                    ) {
                                        impact()
                                        goals.primaryGoal = goal
                                    }
                                }
                            }
                        }

                        // ── Calorie Target
                        SheetSectionCard(label: "DAILY CALORIE TARGET") {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(Int(goals.calorieTarget))")
                                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(Palette.ink)
                                    Text("kcal")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Palette.inkSecondary)
                                }

                                Slider(value: $goals.calorieTarget, in: 1200...4000, step: 50)
                                    .tint(Palette.soleil)

                                HStack {
                                    Text("1,200")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Palette.inkTertiary)
                                    Spacer()
                                    Text("4,000")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(Palette.inkTertiary)
                                }
                            }
                        }

                        // ── Macro Targets
                        SheetSectionCard(label: "MACRO TARGETS") {
                            VStack(spacing: 20) {
                                MacroSliderRow(label: "PROTEIN", value: $goals.proteinTarget, range: 50...300, color: Palette.burn)
                                MacroSliderRow(label: "CARBS",   value: $goals.carbTarget,    range: 50...500, color: Palette.fuel)
                                MacroSliderRow(label: "FAT",     value: $goals.fatTarget,     range: 20...200, color: Palette.pulse)
                            }
                        }

                        // ── Weekly Workouts
                        SheetSectionCard(label: "WEEKLY WORKOUT FREQUENCY") {
                            VStack(spacing: 16) {
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(goals.weeklyWorkouts)")
                                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(Palette.ink)
                                    Text("days / week")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Palette.inkSecondary)
                                }

                                HStack(spacing: 10) {
                                    ForEach(1...7, id: \.self) { day in
                                        Button {
                                            impact()
                                            goals.weeklyWorkouts = day
                                        } label: {
                                            Text("\(day)")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(goals.weeklyWorkouts == day ? Color(hexString: "141410") : Palette.inkSecondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    goals.weeklyWorkouts == day ? Palette.soleil : Color(UIColor.systemGroupedBackground),
                                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // ── Water Target
                        SheetSectionCard(label: "DAILY WATER TARGET") {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(Int(goals.waterTarget))")
                                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(Palette.ink)
                                    Text("oz / day")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(Palette.inkSecondary)
                                }
                                Slider(value: $goals.waterTarget, in: 32...200, step: 8)
                                    .tint(Palette.pulse)
                            }
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Edit Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.inkSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        impact(.medium)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.soleil)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hexString: "F7F5F2"))
    }
}

private struct GoalOptionRow: View {
    let goal: ProfileFitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? goal.accentColor : goal.accentColor.opacity(0.10))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: goal.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : goal.accentColor)
                    )
                Text(goal.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(goal.accentColor)
                }
            }
            .padding(14)
            .background(
                isSelected ? goal.accentColor.opacity(0.08) : Color(UIColor.systemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? goal.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MacroSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(color)
                Spacer()
                Text("\(Int(value))g")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.ink)
            }
            Slider(value: $value, in: range, step: 5)
                .tint(color)
        }
    }
}

// MARK: - Edit Name Sheet

struct EditNameSheet: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexString: "F7F5F2").ignoresSafeArea()

                VStack(spacing: 32) {
                    // Avatar preview
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Palette.soleilLight, Palette.soleilDeep],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Text(String(name.prefix(1).uppercased()))
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundStyle(Color(hexString: "141410"))
                    }
                    .padding(.top, 24)

                    SheetSectionCard(label: "YOUR NAME") {
                        TextField("Name", text: $name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .focused($focused)
                            .onAppear { focused = true }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.inkSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        impact(.medium)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.soleil)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hexString: "F7F5F2"))
    }
}

// MARK: - Units Sheet

struct UnitsSheet: View {
    @Binding var selection: ProfileViewModel.UnitSystem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexString: "F7F5F2").ignoresSafeArea()
                VStack(spacing: 24) {
                    SheetSectionCard(label: "MEASUREMENT SYSTEM") {
                        VStack(spacing: 10) {
                            ForEach(ProfileViewModel.UnitSystem.allCases, id: \.rawValue) { system in
                                Button {
                                    impact()
                                    selection = system
                                } label: {
                                    HStack {
                                        Text(system.rawValue)
                                            .font(.system(size: 15, weight: selection == system ? .semibold : .medium))
                                            .foregroundStyle(Palette.ink)
                                        Spacer()
                                        if selection == system {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Palette.soleil)
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        selection == system ? Palette.soleilTint : Color(UIColor.systemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .strokeBorder(selection == system ? Palette.soleil.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    Spacer()
                }
            }
            .navigationTitle("Units")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.soleil)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hexString: "F7F5F2"))
    }
}

// MARK: - Appearance Sheet

struct AppearanceSheet: View {
    @Binding var selection: ProfileViewModel.AppearanceMode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexString: "F7F5F2").ignoresSafeArea()
                VStack(spacing: 24) {
                    SheetSectionCard(label: "COLOR SCHEME") {
                        VStack(spacing: 10) {
                            ForEach(ProfileViewModel.AppearanceMode.allCases, id: \.rawValue) { mode in
                                Button {
                                    impact()
                                    selection = mode
                                } label: {
                                    HStack {
                                        Text(mode.rawValue)
                                            .font(.system(size: 15, weight: selection == mode ? .semibold : .medium))
                                            .foregroundStyle(Palette.ink)
                                        Spacer()
                                        if selection == mode {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Palette.soleil)
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        selection == mode ? Palette.soleilTint : Color(UIColor.systemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .strokeBorder(selection == mode ? Palette.soleil.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    Spacer()
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.soleil)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hexString: "F7F5F2"))
    }
}

// MARK: - Feedback Sheet

struct FeedbackSheet: View {
    @ObservedObject var vm: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var textFocused: Bool

    private var canSubmit: Bool {
        !vm.feedbackText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hexString: "F7F5F2").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // ── Category picker
                        SheetSectionCard(label: "CATEGORY") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(FeedbackCategory.allCases) { cat in
                                        Button {
                                            impact()
                                            vm.feedbackCategory = cat
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: cat.icon)
                                                    .font(.system(size: 12, weight: .semibold))
                                                Text(cat.rawValue)
                                                    .font(.system(size: 13, weight: .semibold))
                                            }
                                            .foregroundStyle(vm.feedbackCategory == cat ? Color(hexString: "141410") : Palette.inkSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                vm.feedbackCategory == cat ? Palette.soleil : Color(UIColor.systemGroupedBackground),
                                                in: Capsule()
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.feedbackCategory)
                                    }
                                }
                            }
                        }

                        // ── Message
                        SheetSectionCard(label: "YOUR MESSAGE") {
                            VStack(alignment: .leading, spacing: 0) {
                                TextEditor(text: $vm.feedbackText)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Palette.ink)
                                    .focused($textFocused)
                                    .frame(minHeight: 140)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .onAppear { textFocused = true }

                                if vm.feedbackText.isEmpty {
                                    Text("Tell us what's on your mind…")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Palette.inkTertiary)
                                        .allowsHitTesting(false)
                                        .padding(.top, -142)
                                        .padding(.leading, 4)
                                }

                                HStack {
                                    Spacer()
                                    Text("\(vm.feedbackText.count) / 500")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(vm.feedbackText.count > 450 ? Palette.burn : Palette.inkTertiary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .onChange(of: vm.feedbackText) { newValue in
                            if newValue.count > 500 {
                                vm.feedbackText = String(newValue.prefix(500))
                            }
                        }

                        // ── Submit CTA
                        Button {
                            vm.submitFeedback()
                        } label: {
                            ZStack {
                                if vm.isSendingFeedback {
                                    ProgressView()
                                        .tint(Color(hexString: "141410"))
                                } else {
                                    Text("Send Feedback")
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundStyle(Color(hexString: "141410"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(
                                canSubmit
                                    ? LinearGradient(colors: [Palette.soleilLight, Palette.soleilDeep],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color(UIColor.systemGroupedBackground), Color(UIColor.systemGroupedBackground)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmit || vm.isSendingFeedback)
                        .animation(.easeInOut(duration: 0.2), value: canSubmit)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            .onChange(of: vm.showFeedbackSuccess) { success in
                if success { dismiss() }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hexString: "F7F5F2"))
    }
}

// MARK: - Shared Sheet Section Card

private struct SheetSectionCard<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Palette.inkSecondary)
            content()
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 6)
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Toast Modifier

private struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if isPresented {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.formeSuccess)
                    Text(message)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white, in: Capsule())
                .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
                .padding(.bottom, 48)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.spring()) { isPresented = false }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message))
    }
}

// MARK: - Preview

#Preview {
    ProfileScreen()
}

