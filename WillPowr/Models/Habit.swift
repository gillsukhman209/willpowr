import Foundation
import SwiftData

// MARK: - Goal Units

enum GoalUnit: String, CaseIterable, Codable {
    case steps = "steps"
    case minutes = "minutes"
    case hours = "hours"
    case liters = "liters"
    case glasses = "glasses"
    case grams = "grams"
    case count = "count"
    case none = "none" // for binary habits (complete/incomplete)
    
    var displayName: String {
        switch self {
        case .steps: return "steps"
        case .minutes: return "min"
        case .hours: return "hrs"
        case .liters: return "L"
        case .glasses: return "glasses"
        case .grams: return "g"
        case .count: return "times"
        case .none: return ""
        }
    }
    
    var longDisplayName: String {
        switch self {
        case .steps: return "steps"
        case .minutes: return "minutes"
        case .hours: return "hours"
        case .liters: return "liters"
        case .glasses: return "glasses"
        case .grams: return "grams"
        case .count: return "times"
        case .none: return ""
        }
    }
}

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitType: HabitType
    var iconName: String
    var streak: Int
    var isCompleted: Bool
    var lastCompletionDate: Date?
    var createdDate: Date
    var isCustom: Bool
    
    // MARK: - Goal Properties
    var goalTarget: Double = 1.0 // Default value for migration
    var goalUnit: GoalUnit = GoalUnit.none // Default value for migration
    var currentProgress: Double = 0.0 // Default value for migration
    var goalDescription: String? // Optional for migration
    
    init(name: String, habitType: HabitType, iconName: String, isCustom: Bool = false, goalTarget: Double = 1, goalUnit: GoalUnit = .none, goalDescription: String? = nil) {
        self.id = UUID()
        self.name = name
        self.habitType = habitType
        self.iconName = iconName
        self.streak = 0
        self.isCompleted = false
        self.lastCompletionDate = nil
        self.createdDate = Date()
        self.isCustom = isCustom
        self.goalTarget = goalTarget
        self.goalUnit = goalUnit
        self.currentProgress = 0
        self.goalDescription = goalDescription
    }
    
    // MARK: - Computed Properties
    
    var isGoalMet: Bool {
        if goalUnit == .none {
            return isCompleted
        }
        return currentProgress >= goalTarget
    }
    
    var progressPercentage: Double {
        guard goalTarget > 0 else { return 0 }
        return min(currentProgress / goalTarget, 1.0)
    }
    
    var displayProgress: String {
        if goalUnit == .none {
            return isCompleted ? "Complete" : "Not Complete"
        }
        
        let current = formatValue(currentProgress)
        let target = formatValue(goalTarget)
        
        return "\(current) / \(target) \(goalUnit.displayName)"
    }
    
    var canCompleteToday: Bool {
        guard let lastDate = lastCompletionDate else { return true }
        return !Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Habit Type Enum

enum HabitType: String, CaseIterable, Codable {
    case build = "build"
    case quit = "quit"
    
    var displayName: String {
        switch self {
        case .build: return "Build"
        case .quit: return "Quit"
        }
    }
    
    var color: String {
        switch self {
        case .build: return "green"
        case .quit: return "red"
        }
    }
}

// MARK: - Preset Habits

struct PresetHabit {
    let name: String
    let iconName: String
    let habitType: HabitType
    let defaultGoalTarget: Double
    let defaultGoalUnit: GoalUnit
    let goalDescription: String?
    
    init(name: String, iconName: String, habitType: HabitType, defaultGoalTarget: Double = 1, defaultGoalUnit: GoalUnit = .none, goalDescription: String? = nil) {
        self.name = name
        self.iconName = iconName
        self.habitType = habitType
        self.defaultGoalTarget = defaultGoalTarget
        self.defaultGoalUnit = defaultGoalUnit
        self.goalDescription = goalDescription
    }
}

extension PresetHabit {
    static let buildHabits: [PresetHabit] = [
        PresetHabit(name: "Walk Daily", iconName: "figure.walk", habitType: .build, defaultGoalTarget: 8000, defaultGoalUnit: .steps, goalDescription: "Walk 8,000 steps daily"),
        PresetHabit(name: "Meditate", iconName: "brain.head.profile", habitType: .build, defaultGoalTarget: 10, defaultGoalUnit: .minutes, goalDescription: "Meditate for 10 minutes daily"),
        PresetHabit(name: "Drink Water", iconName: "drop.fill", habitType: .build, defaultGoalTarget: 2, defaultGoalUnit: .liters, goalDescription: "Drink 2 liters of water daily"),
        PresetHabit(name: "Read", iconName: "book.fill", habitType: .build, defaultGoalTarget: 20, defaultGoalUnit: .minutes, goalDescription: "Read for 20 minutes daily"),
        PresetHabit(name: "Exercise", iconName: "dumbbell.fill", habitType: .build, defaultGoalTarget: 30, defaultGoalUnit: .minutes, goalDescription: "Exercise for 30 minutes daily"),
        PresetHabit(name: "Journal", iconName: "pencil.and.outline", habitType: .build, defaultGoalTarget: 1, defaultGoalUnit: .none, goalDescription: "Write in journal daily"),
        PresetHabit(name: "Sleep Early", iconName: "bed.double.fill", habitType: .build, defaultGoalTarget: 1, defaultGoalUnit: .none, goalDescription: "Sleep before 11 PM daily")
    ]
    
    static let quitHabits: [PresetHabit] = [
        PresetHabit(name: "Limit Social Media", iconName: "iphone.slash", habitType: .quit, defaultGoalTarget: 1, defaultGoalUnit: .hours, goalDescription: "Limit social media to 1 hour daily"),
        PresetHabit(name: "Reduce Sugar", iconName: "cube.fill", habitType: .quit, defaultGoalTarget: 25, defaultGoalUnit: .grams, goalDescription: "Consume less than 25g sugar daily"),
        PresetHabit(name: "Quit Smoking", iconName: "smoke.fill", habitType: .quit, defaultGoalTarget: 0, defaultGoalUnit: .count, goalDescription: "Smoke 0 cigarettes daily"),
        PresetHabit(name: "Limit Junk Food", iconName: "takeoutbag.and.cup.and.straw.fill", habitType: .quit, defaultGoalTarget: 1, defaultGoalUnit: .count, goalDescription: "Limit junk food to 1 serving daily"),
        PresetHabit(name: "Reduce Procrastination", iconName: "clock.fill", habitType: .quit, defaultGoalTarget: 1, defaultGoalUnit: .none, goalDescription: "Avoid procrastination daily"),
        PresetHabit(name: "Stop Negative Thinking", iconName: "brain.filled.head.profile", habitType: .quit, defaultGoalTarget: 1, defaultGoalUnit: .none, goalDescription: "Practice positive thinking daily"),
        PresetHabit(name: "Limit Screen Time", iconName: "tv.fill", habitType: .quit, defaultGoalTarget: 6, defaultGoalUnit: .hours, goalDescription: "Limit screen time to 6 hours daily")
    ]
    
    static let allPresets: [PresetHabit] = buildHabits + quitHabits
} 