import Foundation
import SwiftUI

struct MacroData {
    let grams: Int
    let goal: Int
}

struct MacrosData {
    let protein: MacroData
    let carbs: MacroData
    let fat: MacroData
}

struct CalorieData {
    let consumed: Int
    let burned: Int
    let goal: Int
    
    var net: Int { consumed - burned }
    var remaining: Int { goal - net }
    var isOverGoal: Bool { net > goal }
}

struct WorkoutEntry: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let kcal: Int
    let colorHex: String
    let bgHex: String
}

struct WorkoutPlan {
    let dayNumber: Int
    let totalDays: Int
    let category: String
    let workoutName: String
    let type: String
    let difficulty: String
    let durationMinutes: Int
    let estimatedKcal: Int
    let exercises: [String]
}

struct SummaryData {
    let label: String
    let date: String
    let calories: CalorieData
    let macros: MacrosData
    let workouts: [WorkoutEntry]
}

enum DashboardMock {
    static let summary: SummaryData = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let currentDate = formatter.string(from: Date())
        
        let calories = CalorieData(consumed: 1850, burned: 420, goal: 2200)
        let macros = MacrosData(
            protein: MacroData(grams: 120, goal: 150),
            carbs: MacroData(grams: 180, goal: 220),
            fat: MacroData(grams: 60, goal: 70)
        )
        let workouts = [
            WorkoutEntry(emoji: "🏋️‍♂️", name: "Strength Training", kcal: 230, colorHex: "#FF6B6B", bgHex: "#FFF0F0"),
            WorkoutEntry(emoji: "🚴‍♀️", name: "Cycling", kcal: 180, colorHex: "#4ECDC4", bgHex: "#E0FFFB"),
            WorkoutEntry(emoji: "🤸‍♀️", name: "Yoga", kcal: 120, colorHex: "#556270", bgHex: "#F0F4F8")
        ]
        
        return SummaryData(
            label: "TODAY",
            date: currentDate,
            calories: calories,
            macros: macros,
            workouts: workouts
        )
    }()
    
    static let plan = WorkoutPlan(
        dayNumber: 4,
        totalDays: 28,
        category: "Push · Upper Power",
        workoutName: "Chest & Shoulders",
        type: "Strength",
        difficulty: "Intermediate",
        durationMinutes: 52,
        estimatedKcal: 340,
        exercises: [
            "Bench Press",
            "Overhead Press",
            "Incline Dumbbell Press",
            "Lateral Raises",
            "Push-ups"
        ]
    )
}
