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
    
    func addHabit(name: String, type: HabitType, iconName: String, isCustom: Bool = false) {
        print("🔧 HabitService.addHabit called with name: \(name), type: \(type)")
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Invalid name: '\(name)'")
            error = .invalidName
            return
        }
        
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            habitType: type,
            iconName: iconName,
            isCustom: isCustom
        )
        
        print("✅ Creating habit: \(habit.name)")
        modelContext.insert(habit)
        saveContext()
        loadHabits()
        print("📊 Total habits after adding: \(habits.count)")
    }
    
    func addPresetHabit(_ preset: PresetHabit) {
        addHabit(
            name: preset.name,
            type: preset.habitType,
            iconName: preset.iconName,
            isCustom: false
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
    
    // MARK: - Habit Actions
    
    func completeHabit(_ habit: Habit) {
        guard habit.canCompleteToday else {
            error = .alreadyCompleted
            return
        }
        
        habit.markCompleted()
        saveContext()
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        objectWillChange.send()
    }
    
    func failHabit(_ habit: Habit) {
        guard habit.habitType == .quit else {
            error = .invalidAction
            return
        }
        
        habit.markFailed()
        saveContext()
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        objectWillChange.send()
    }
    
    func resetHabitStreak(_ habit: Habit) {
        habit.resetStreak()
        saveContext()
        objectWillChange.send()
    }
    
    // MARK: - Statistics
    
    func totalActiveHabits() -> Int {
        return habits.count
    }
    
    func totalStreakDays() -> Int {
        return habits.reduce(0) { $0 + $1.streak }
    }
    
    func buildHabitsCount() -> Int {
        return habits.filter { $0.habitType == .build }.count
    }
    
    func quitHabitsCount() -> Int {
        return habits.filter { $0.habitType == .quit }.count
    }
    
    func habitsCompletedToday() -> Int {
        return habits.filter { $0.isCompletedToday }.count
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
        print("💾 Saving context...")
        do {
            try modelContext.save()
            print("✅ Context saved successfully")
        } catch {
            print("❌ Error saving context: \(error)")
            self.error = .savingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Daily Reset Logic
    
    func checkForMissedDays() {
        let calendar = Calendar.current
        let today = Date()
        
        for habit in habits {
            guard let lastCompleted = habit.lastCompletedDate else { continue }
            
            // Only check build habits for missed days
            if habit.habitType == .build && !calendar.isDateInToday(lastCompleted) {
                let daysBetween = calendar.dateComponents([.day], from: lastCompleted, to: today).day ?? 0
                
                // If more than 1 day has passed, reset streak
                if daysBetween > 1 {
                    habit.resetStreak()
                }
            }
        }
        
        saveContext()
        objectWillChange.send()
    }
    
    // MARK: - Habit Sorting
    
    func sortedHabits() -> [Habit] {
        return habits.sorted { habit1, habit2 in
            // First, prioritize habits that can be completed today
            if habit1.canCompleteToday && !habit2.canCompleteToday {
                return true
            } else if !habit1.canCompleteToday && habit2.canCompleteToday {
                return false
            }
            
            // Then by streak length (longer streaks first)
            if habit1.streak != habit2.streak {
                return habit1.streak > habit2.streak
            }
            
            // Finally by creation date (newer first)
            return habit1.createdDate > habit2.createdDate
        }
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

// MARK: - Habit Error Handling

enum HabitError: LocalizedError {
    case invalidName
    case alreadyCompleted
    case invalidAction
    case loadingFailed(String)
    case savingFailed(String)
    case habitNotFound
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter a valid habit name"
        case .alreadyCompleted:
            return "You've already completed this habit today"
        case .invalidAction:
            return "This action is not valid for this habit type"
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