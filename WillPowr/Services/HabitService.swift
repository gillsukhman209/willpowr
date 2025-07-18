import Foundation
import SwiftData
import SwiftUI

@MainActor
final class HabitService: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var habits: [Habit] = []
    @Published var isLoading = false
    @Published var error: HabitError?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadHabits()
    }
    
    // MARK: - Habit Management
    
    func loadHabits() {
        print("📥 Loading habits...")
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\Habit.createdDate, order: .reverse)]
            )
            habits = try modelContext.fetch(descriptor)
            print("✅ Loaded \(habits.count) habits")
        } catch {
            print("❌ Error loading habits: \(error)")
            self.error = .loadingFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func addHabit(name: String, type: HabitType, iconName: String, isCustom: Bool = false, goalTarget: Double = 1, goalUnit: GoalUnit = .none, goalDescription: String? = nil) {
        print("🔧 HabitService.addHabit called with name: \(name), type: \(type), goal: \(goalTarget) \(goalUnit.displayName)")
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Invalid name: '\(name)'")
            error = .invalidName
            return
        }
        
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            habitType: type,
            iconName: iconName,
            isCustom: isCustom,
            goalTarget: goalTarget,
            goalUnit: goalUnit,
            goalDescription: goalDescription
        )
        
        modelContext.insert(habit)
        
        do {
            try modelContext.save()
            print("✅ Habit saved successfully: \(habit.name)")
            loadHabits()
        } catch {
            print("❌ Error saving habit: \(error)")
            self.error = .savingFailed(error.localizedDescription)
        }
    }
    
    func addPresetHabit(_ preset: PresetHabit) {
        print("🔧 HabitService.addPresetHabit called with preset: \(preset.name)")
        
        addHabit(
            name: preset.name,
            type: preset.habitType,
            iconName: preset.iconName,
            isCustom: false,
            goalTarget: preset.defaultGoalTarget,
            goalUnit: preset.defaultGoalUnit,
            goalDescription: preset.goalDescription
        )
    }
    
    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        saveContext()
        loadHabits()
    }
    
    func updateHabit(_ habit: Habit) {
        saveContext()
        loadHabits()
    }
    
    // MARK: - Habit Completion
    
    func completeHabit(_ habit: Habit) {
        print("🎯 Completing habit: \(habit.name)")
        
        if habit.goalUnit == .none {
            // Binary completion (complete/incomplete)
            markHabitComplete(habit)
        } else {
            // Goal-based completion - complete the goal
            addProgressToHabit(habit, progress: habit.goalTarget)
        }
    }
    
    func addProgressToHabit(_ habit: Habit, progress: Double) {
        print("📊 Adding progress to habit: \(habit.name), progress: \(progress)")
        
        // Reset progress if it's a new day
        if let lastCompletion = habit.lastCompletionDate,
           !Calendar.current.isDate(lastCompletion, inSameDayAs: Date()) {
            habit.currentProgress = 0
        }
        
        // Add progress
        habit.currentProgress = min(habit.currentProgress + progress, habit.goalTarget)
        
        // Check if goal is met
        if habit.currentProgress >= habit.goalTarget && !habit.isGoalMet {
            markHabitComplete(habit)
        }
        
        saveContext()
    }
    
    private func markHabitComplete(_ habit: Habit) {
        let calendar = Calendar.current
        let today = Date()
        
        // Check if already completed today
        if let lastCompletion = habit.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) {
            print("⚠️ Habit already completed today")
            return
        }
        
        // Update streak logic
        if let lastCompletion = habit.lastCompletionDate {
            let daysBetween = calendar.dateComponents([.day], from: lastCompletion, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day - increment streak
                habit.streak += 1
            } else if daysBetween > 1 {
                // Missed days - reset streak
                habit.streak = 1
            }
        } else {
            // First completion
            habit.streak = 1
        }
        
        // Mark as completed
        habit.isCompleted = true
        habit.lastCompletionDate = today
        
        print("✅ Habit completed: \(habit.name), streak: \(habit.streak)")
        saveContext()
    }
    
    func failHabit(_ habit: Habit) {
        print("❌ Failing habit: \(habit.name)")
        
        guard habit.habitType == .quit else {
            print("⚠️ Cannot fail a build habit")
            return
        }
        
        // Reset streak and progress
        habit.streak = 0
        habit.currentProgress = 0
        habit.isCompleted = false
        habit.lastCompletionDate = Date()
        
        saveContext()
    }
    
    func resetHabitStreak(_ habit: Habit) {
        print("🔄 Resetting streak for habit: \(habit.name)")
        
        habit.streak = 0
        habit.currentProgress = 0
        habit.isCompleted = false
        habit.lastCompletionDate = nil
        
        saveContext()
    }
    
    // MARK: - Statistics
    
    func totalActiveHabits() -> Int {
        return habits.count
    }
    
    func habitsCompletedToday() -> Int {
        return habits.filter { habit in
            if habit.goalUnit == .none {
                return habit.isCompleted && habit.canCompleteToday == false // completed today
            } else {
                return habit.isGoalMet
            }
        }.count
    }
    
    func longestStreak() -> Int {
        return habits.map { $0.streak }.max() ?? 0
    }
    
    // MARK: - Habit Validation
    
    func habitExists(name: String) -> Bool {
        return habits.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    func validateHabitName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 50
    }
    
    // MARK: - Private Methods
    
    private func saveContext() {
        do {
            try modelContext.save()
            print("💾 Context saved successfully")
        } catch {
            print("❌ Error saving context: \(error)")
            self.error = .savingFailed(error.localizedDescription)
        }
    }
    
    func habitDescription(for habit: Habit) -> String {
        if let description = habit.goalDescription {
            return description
        } else {
            return "Track your \(habit.name.lowercased()) habit"
        }
    }
    
    // MARK: - Helper Methods
    
    func sortedHabits() -> [Habit] {
        return habits.sorted { habit1, habit2 in
            // Sort by completion status (incomplete first), then by creation date
            if habit1.isGoalMet != habit2.isGoalMet {
                return !habit1.isGoalMet && habit2.isGoalMet
            }
            return habit1.createdDate < habit2.createdDate
        }
    }
    
    func checkForMissedDays() {
        let calendar = Calendar.current
        let today = Date()
        
        for habit in habits {
            guard let lastCompletion = habit.lastCompletionDate else { continue }
            
            let daysBetween = calendar.dateComponents([.day], from: lastCompletion, to: today).day ?? 0
            
            if daysBetween > 1 {
                // Missed days - reset streak and progress
                habit.streak = 0
                habit.currentProgress = 0
                habit.isCompleted = false
                print("📅 Reset streak for \(habit.name) due to missed days")
            } else if daysBetween == 1 {
                // New day - reset daily progress but keep streak
                habit.currentProgress = 0
                habit.isCompleted = false
                print("🌅 Reset daily progress for \(habit.name)")
            }
        }
        
        saveContext()
    }
    
    // MARK: - Debug Methods
    
    func deleteAllHabits() {
        print("🗑️ Debug: Deleting all habits...")
        
        do {
            // Delete all habits from the database
            let descriptor = FetchDescriptor<Habit>()
            let allHabits = try modelContext.fetch(descriptor)
            
            for habit in allHabits {
                modelContext.delete(habit)
            }
            
            try modelContext.save()
            
            // Reset local state
            habits.removeAll()
            
            print("✅ Debug: Successfully deleted \(allHabits.count) habits")
        } catch {
            print("❌ Debug: Error deleting all habits: \(error)")
            self.error = .deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
}

// MARK: - Habit Error

enum HabitError: Error, LocalizedError {
    case invalidName
    case loadingFailed(String)
    case savingFailed(String)
    case habitNotFound
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter a valid habit name"
        case .loadingFailed(let message):
            return "Failed to load habits: \(message)"
        case .savingFailed(let message):
            return "Failed to save habit: \(message)"
        case .habitNotFound:
            return "Habit not found"
        case .deleteFailed(let message):
            return "Failed to delete habits: \(message)"
        }
    }
}

// MARK: - Habit Service Environment

struct HabitServiceKey: EnvironmentKey {
    static let defaultValue: HabitService? = nil
}

extension EnvironmentValues {
    var habitService: HabitService? {
        get { self[HabitServiceKey.self] }
        set { self[HabitServiceKey.self] = newValue }
    }
} 