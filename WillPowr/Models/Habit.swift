import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitType: HabitType
    var streak: Int
    var lastCompletedDate: Date?
    var createdDate: Date
    var iconName: String
    var isCustom: Bool
    
    init(name: String, habitType: HabitType, iconName: String = "star.fill", isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.habitType = habitType
        self.streak = 0
        self.lastCompletedDate = nil
        self.createdDate = Date()
        self.iconName = iconName
        self.isCustom = isCustom
    }
    
    // MARK: - Computed Properties
    
    var streakText: String {
        return streak == 0 ? "Start your streak!" : "\(streak) day\(streak == 1 ? "" : "s")"
    }
    
    var canCompleteToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return true }
        return !Calendar.current.isDateInToday(lastCompleted)
    }
    
    var isCompletedToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(lastCompleted)
    }
    
    // MARK: - Habit Actions
    
    func markCompleted() {
        guard canCompleteToday else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        if let lastCompleted = lastCompletedDate {
            let daysBetween = calendar.dateComponents([.day], from: lastCompleted, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day - increment streak
                streak += 1
            } else {
                // Missed days - reset streak
                streak = 1
            }
        } else {
            // First completion
            streak = 1
        }
        
        lastCompletedDate = today
    }
    
    func markFailed() {
        guard habitType == .quit else { return }
        streak = 0
        lastCompletedDate = Date()
    }
    
    func resetStreak() {
        streak = 0
        lastCompletedDate = nil
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
}

extension PresetHabit {
    static let buildHabits: [PresetHabit] = [
        PresetHabit(name: "Walk Daily", iconName: "figure.walk", habitType: .build),
        PresetHabit(name: "Meditate", iconName: "brain.head.profile", habitType: .build),
        PresetHabit(name: "Drink Water", iconName: "drop.fill", habitType: .build),
        PresetHabit(name: "Read", iconName: "book.fill", habitType: .build),
        PresetHabit(name: "Exercise", iconName: "dumbbell.fill", habitType: .build),
        PresetHabit(name: "Journal", iconName: "pencil.and.outline", habitType: .build),
        PresetHabit(name: "Sleep Early", iconName: "bed.double.fill", habitType: .build)
    ]
    
    static let quitHabits: [PresetHabit] = [
        PresetHabit(name: "Social Media", iconName: "iphone.slash", habitType: .quit),
        PresetHabit(name: "Sugar", iconName: "cube.transparent.slash", habitType: .quit),
        PresetHabit(name: "Smoking", iconName: "smoke.fill", habitType: .quit),
        PresetHabit(name: "Junk Food", iconName: "fork.knife.slash", habitType: .quit),
        PresetHabit(name: "Procrastination", iconName: "clock.badge.xmark", habitType: .quit),
        PresetHabit(name: "Negative Thinking", iconName: "brain.head.profile.slash", habitType: .quit),
        PresetHabit(name: "Screen Time", iconName: "tv.slash", habitType: .quit)
    ]
    
    static let allPresets: [PresetHabit] = buildHabits + quitHabits
} 