import Foundation
import SwiftData
import SwiftUI
import Combine // Added for Combine publishers

@MainActor
final class HabitService: ObservableObject {
    private let modelContext: ModelContext
    private let dateManager: DateManager
    
    @Published var habits: [Habit] = []
    @Published var isLoading = false
    @Published var error: HabitError?
    
    init(modelContext: ModelContext, dateManager: DateManager? = nil) {
        self.modelContext = modelContext
        self.dateManager = dateManager ?? DateManager()
        loadHabits()
        
        // Migrate existing habits to have proper longestStreak values
        migrateExistingHabits()
        
        // Listen for specific date changes, not all DateManager changes
        self.dateManager.$dateDidChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshHabitStatesForCurrentDate()
            }
        }.store(in: &cancellables)
    }
    
    // MARK: - Migration
    
    /// Migrate existing habits that don't have longestStreak set
    private func migrateExistingHabits() {
        var needsSave = false
        
        for habit in habits {
            // If longestStreak is 0 but current streak is greater, set it
            if habit.longestStreak == 0 && habit.streak > 0 {
                habit.longestStreak = habit.streak
                print("📦 Migrating \(habit.name): setting longestStreak to \(habit.streak)")
                needsSave = true
            }
        }
        
        if needsSave {
            saveContext()
            print("✅ Migration completed for existing habits")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        if habit.habitType == .quit {
            // For quit habits, "completing" means successfully avoiding the bad habit
            markQuitHabitSuccess(habit)
        } else if habit.goalUnit == .none {
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
           !Calendar.current.isDate(lastCompletion, inSameDayAs: dateManager.currentDate) {
            habit.currentProgress = 0
        }
        
        // Track if habit was already completed today before adding progress
        let wasAlreadyCompleted = habit.isCompleted
        
        // Add progress
        habit.currentProgress = min(habit.currentProgress + progress, habit.goalTarget)
        
        // Check if goal is met and habit wasn't already completed today
        if habit.currentProgress >= habit.goalTarget && !wasAlreadyCompleted {
            print("🎯 Goal reached! Calling markHabitComplete...")
            markHabitComplete(habit)
        } else if habit.currentProgress >= habit.goalTarget && wasAlreadyCompleted {
            print("⚠️ Goal reached but habit already completed today")
        } else {
            print("📊 Progress added but goal not yet reached: \(habit.currentProgress)/\(habit.goalTarget)")
        }
        
        saveContext()
    }
    
    private func markHabitComplete(_ habit: Habit) {
        let calendar = Calendar.current
        let today = dateManager.currentDate
        
        print("🎯 markHabitComplete called for: \(habit.name) on \(dateManager.formatDebugDate())")
        print("   Previous streak: \(habit.streak)")
        print("   Last completion: \(habit.lastCompletionDate?.description ?? "none")")
        
        // Check if already completed today
        if let lastCompletion = habit.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) {
            print("⚠️ Habit already completed today, skipping")
            return
        }
        
        // Update streak logic
        if let lastCompletion = habit.lastCompletionDate {
            let daysBetween = calendar.dateComponents([.day], from: lastCompletion, to: today).day ?? 0
            print("   Days between last completion and today: \(daysBetween)")
            
            if daysBetween == 1 {
                // Consecutive day - increment streak
                habit.streak += 1
                print("   ✅ Consecutive day! New streak: \(habit.streak)")
            } else if daysBetween > 1 {
                // Missed days - reset streak to 1
                habit.streak = 1
                print("   🔄 Missed days, streak reset to: \(habit.streak)")
            } else {
                // Same day completion (shouldn't happen due to check above)
                print("   ⚠️ Same day completion detected")
                return
            }
        } else {
            // First completion
            habit.streak = 1
            print("   🎉 First completion! Streak set to: \(habit.streak)")
        }
        
        // Mark as completed
        habit.isCompleted = true
        habit.lastCompletionDate = today
        
        // Update longest streak if we've achieved a new record
        if habit.streak > habit.longestStreak {
            habit.longestStreak = habit.streak
            print("🏆 NEW RECORD! Longest streak updated to: \(habit.longestStreak)")
        }
        
        print("✅ Habit marked complete: \(habit.name), Final streak: \(habit.streak), Longest ever: \(habit.longestStreak)")
        saveContext()
    }
    
    // MARK: - Quit Habit Helpers
    
    /// Check if a quit habit has been interacted with today (success or failure)
    private func hasInteractedToday(_ habit: Habit) -> Bool {
        guard habit.habitType == .quit else { return false }
        
        let today = dateManager.currentDate
        let calendar = Calendar.current
        
        // Check if succeeded today
        if let lastCompletion = habit.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) {
            return true
        }
        
        // Check if failed today (streak = 0 and it's a quit habit could indicate recent failure)
        // This is a simple heuristic - could be improved with a dedicated lastFailureDate property
        if habit.streak == 0 && habit.habitType == .quit {
            // Additional check: if this habit had a streak yesterday but has 0 today, 
            // it likely failed today
            return true
        }
        
        return false
    }
    
    func markQuitHabitSuccess(_ habit: Habit) {
        let calendar = Calendar.current
        let today = dateManager.currentDate
        
        print("✅ markQuitHabitSuccess called for: \(habit.name) on \(dateManager.formatDebugDate())")
        print("   Previous streak: \(habit.streak)")
        print("   Last success date: \(habit.lastCompletionDate?.description ?? "none")")
        print("   Is completed: \(habit.isCompleted)")
        
        // Check if already marked successful today
        if let lastCompletion = habit.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) {
            print("⚠️ Quit habit already marked successful today, skipping")
            return
        }
        
        // Update streak logic for quit habits - ONLY count consecutive explicit successes
        if let lastSuccess = habit.lastCompletionDate {
            let daysBetween = calendar.dateComponents([.day], from: lastSuccess, to: today).day ?? 0
            print("   Days between last success and today: \(daysBetween)")
            
            if daysBetween == 1 {
                // Consecutive successful day - increment streak
                habit.streak += 1
                print("   ✅ Consecutive success! New streak: \(habit.streak)")
            } else {
                // Gap in successes - reset streak to 1 (only today counts)
                habit.streak = 1
                print("   🔄 Gap detected - streak reset to: \(habit.streak)")
            }
        } else {
            // First success ever
            habit.streak = 1
            print("   🎉 First quit habit success! Streak set to: \(habit.streak)")
        }
        
        // Mark as successful
        habit.isCompleted = true
        habit.lastCompletionDate = today
        
        // Update longest streak if we've achieved a new record
        if habit.streak > habit.longestStreak {
            habit.longestStreak = habit.streak
            print("🏆 NEW QUIT HABIT RECORD! Longest streak updated to: \(habit.longestStreak)")
        }
        
        print("✅ Quit habit marked successful: \(habit.name), Final streak: \(habit.streak), Longest ever: \(habit.longestStreak)")
        saveContext()
    }
    
    func failHabit(_ habit: Habit) {
        print("❌ Failing habit: \(habit.name)")
        
        guard habit.habitType == .quit else {
            print("⚠️ Cannot fail a build habit")
            return
        }
        
        let today = dateManager.currentDate
        let calendar = Calendar.current
        
        // Check if already marked successful today - prevent changing success to failure
        if let lastCompletion = habit.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) && habit.isCompleted {
            print("⚠️ Already succeeded today, cannot change to failure")
            return
        }
        
        // Reset streak and progress
        habit.streak = 0
        habit.currentProgress = 0
        habit.isCompleted = false
        // Don't set lastCompletionDate for failures - only track successful completions
        
        print("❌ Habit failed: \(habit.name), Streak reset to: 0")
        saveContext()
    }
    
    func resetHabitStreak(_ habit: Habit) {
        print("🔄 Resetting current streak for habit: \(habit.name)")
        print("   Current streak: \(habit.streak) → 0")
        print("   Longest streak remains: \(habit.longestStreak)")
        
        habit.streak = 0
        habit.currentProgress = 0
        habit.isCompleted = false
        habit.lastCompletionDate = nil
        // Note: longestStreak is intentionally NOT reset - it's a historical record
        
        saveContext()
    }
    
    // MARK: - Statistics
    
    func totalActiveHabits() -> Int {
        return habits.count
    }
    
    func habitsCompletedToday() -> Int {
        return habits.filter { habit in
            if habit.goalUnit == .none {
                return habit.isCompleted && !habit.canComplete(on: dateManager.currentDate) // completed today
            } else {
                return habit.isGoalMet
            }
        }.count
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
        let today = dateManager.currentDate
        
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
    
    // MARK: - Date-Aware State Management
    
    /// Refresh all habit states to reflect the current debug date
    func refreshHabitStatesForCurrentDate() {
        print("🔄 Refreshing habit states for date: \(dateManager.formatDebugDate())")
        
        for habit in habits {
            let wasCompleted = habit.isCompleted
            let previousProgress = habit.currentProgress
            
            // Reset daily progress for the current date
            if let lastCompletion = habit.lastCompletionDate,
               Calendar.current.isDate(lastCompletion, inSameDayAs: dateManager.currentDate) {
                // Habit was completed on this date - mark as completed
                habit.isCompleted = true
                if habit.goalUnit != .none {
                    habit.currentProgress = habit.goalTarget
                }
                print("   ✅ \(habit.name): Completed on this date (streak: \(habit.streak))")
            } else {
                // Habit was not completed on this date - reset state
                habit.isCompleted = false
                habit.currentProgress = 0
                print("   ❌ \(habit.name): Not completed on this date (streak: \(habit.streak))")
            }
            
            // Only log if something actually changed
            if wasCompleted != habit.isCompleted || previousProgress != habit.currentProgress {
                print("   🔄 \(habit.name): Changed from completed=\(wasCompleted) to completed=\(habit.isCompleted)")
            }
        }
        
        // Save the updated states
        saveContext()
        print("💾 Habit states refreshed and saved")
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