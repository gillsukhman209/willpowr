import Foundation
import SwiftData

@Model
final class HabitEntry {
    var id: UUID
    var habitId: UUID
    var date: Date
    var progress: Double
    var goalTarget: Double
    var goalUnit: GoalUnit
    var habitType: HabitType
    var quitHabitType: QuitHabitType
    var isCompleted: Bool
    var notes: String?
    var createdAt: Date
    
    // Relationship to the habit (optional since we store habitId)
    var habit: Habit?
    
    init(
        habitId: UUID,
        date: Date,
        progress: Double,
        goalTarget: Double,
        goalUnit: GoalUnit,
        habitType: HabitType,
        quitHabitType: QuitHabitType = .abstinence,
        isCompleted: Bool,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.habitId = habitId
        self.date = Calendar.current.startOfDay(for: date) // Normalize to start of day
        self.progress = progress
        self.goalTarget = goalTarget
        self.goalUnit = goalUnit
        self.habitType = habitType
        self.quitHabitType = quitHabitType
        self.isCompleted = isCompleted
        self.notes = notes
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Double {
        guard goalTarget > 0 else { return isCompleted ? 1.0 : 0.0 }
        return min(progress / goalTarget, 1.0)
    }
    
    var isGoalMet: Bool {
        if goalUnit == .none {
            return isCompleted
        }
        return progress >= goalTarget
    }
    
    var displayProgress: String {
        if habitType == .quit && quitHabitType == .abstinence {
            return isCompleted ? "Stayed Clean" : "Relapsed"
        }
        
        if goalUnit == .none {
            return isCompleted ? "✅ Complete" : "❌ Incomplete"
        }
        
        let current = formatValue(progress)
        let target = formatValue(goalTarget)
        
        if habitType == .quit && quitHabitType == .limit {
            let status = progress <= goalTarget ? "✅" : "⚠️"
            return "\(status) \(current) / \(target) \(goalUnit.displayName)"
        }
        
        return "\(current) / \(target) \(goalUnit.displayName)"
    }
    
    var statusIcon: String {
        if habitType == .quit && quitHabitType == .abstinence {
            return isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill"
        }
        
        if goalUnit == .none {
            return isCompleted ? "checkmark.circle.fill" : "circle"
        }
        
        if habitType == .quit && quitHabitType == .limit {
            return progress <= goalTarget ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
        }
        
        return isGoalMet ? "checkmark.circle.fill" : "circle"
    }
    
    var statusColor: String {
        if habitType == .quit && quitHabitType == .abstinence {
            return isCompleted ? "green" : "red"
        }
        
        if habitType == .quit && quitHabitType == .limit {
            return progress <= goalTarget ? "green" : "orange"
        }
        
        return isGoalMet ? "green" : "gray"
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Extensions

extension HabitEntry {
    static func createEntry(from habit: Habit, on date: Date = Date()) -> HabitEntry {
        return HabitEntry(
            habitId: habit.id,
            date: date,
            progress: habit.currentProgress,
            goalTarget: habit.goalTarget,
            goalUnit: habit.goalUnit,
            habitType: habit.habitType,
            quitHabitType: habit.quitHabitType,
            isCompleted: habit.isCompleted
        )
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}