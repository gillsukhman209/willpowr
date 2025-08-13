import Foundation
import SwiftData
import SwiftUI
import Combine // Added for Combine publishers

@MainActor
final class HabitService: ObservableObject {
    private let modelContext: ModelContext
    let dateManager: DateManager
    private weak var notificationService: NotificationService?
    
    @Published var habits: [Habit] = []
    @Published var isLoading = false
    @Published var error: HabitError?
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    
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
    
    // MARK: - Notification Service Integration
    
    func setNotificationService(_ service: NotificationService) {
        notificationService = service
    }
    
    private func updateNotifications() {
        guard let notificationService = notificationService else { return }
        // Use debounced updates to prevent excessive notifications
        notificationService.updateNotificationsForHabitChange(self)
    }
    
    // MARK: - Habit Management
    
    func loadHabits() {
        print("📥 Loading habits...")
        print("📥 Model context: \(modelContext)")
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\Habit.createdDate, order: .reverse)]
            )
            let fetchedHabits = try modelContext.fetch(descriptor)
            print("✅ Loaded \(fetchedHabits.count) habits")
            
            // Test accessing trackingMode to catch casting errors
            var validHabits: [Habit] = []
            for habit in fetchedHabits {
                do {
                    // Try to access trackingMode - this will trigger casting error if property doesn't exist
                    let _ = habit.trackingMode
                    validHabits.append(habit)
                    print("📱 Valid habit: \(habit.name) - trackingMode: \(habit.trackingMode)")
                } catch {
                    print("⚠️ Casting error for habit \(habit.name): \(error.localizedDescription)")
                    print("🔧 This habit has corrupted data - will be excluded")
                }
            }
            
            // If we have casting errors, clear all data to start fresh
            if validHabits.count != fetchedHabits.count {
                print("🗑️ Detected \(fetchedHabits.count - validHabits.count) corrupted habits - clearing database for schema migration")
                deleteAllHabits()
                habits = []
            } else {
                habits = validHabits
            }
            
        } catch {
            print("❌ Error loading habits: \(error)")
            self.error = .loadingFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func addHabit(name: String, type: HabitType, iconName: String, isCustom: Bool = false, goalTarget: Double = 1, goalUnit: GoalUnit = .none, goalDescription: String? = nil, trackingMode: TrackingMode = .manual, quitHabitType: QuitHabitType = .abstinence) {
        print("🔧 HabitService.addHabit called with name: \(name), type: \(type), goal: \(goalTarget) \(goalUnit.displayName), trackingMode: \(trackingMode)")
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            print("❌ Invalid name: '\(name)'")
            error = .invalidName
            return
        }
        
        guard !habitExists(name: trimmedName) else {
            print("❌ Duplicate habit: '\(trimmedName)' already exists")
            error = .duplicateHabit
            return
        }
        
        let habit = Habit(
            name: trimmedName,
            habitType: type,
            iconName: iconName,
            isCustom: isCustom,
            goalTarget: goalTarget,
            goalUnit: goalUnit,
            goalDescription: goalDescription,
            trackingMode: trackingMode,
            quitHabitType: quitHabitType
        )
        
        modelContext.insert(habit)
        
        do {
            try modelContext.save()
            print("✅ Habit saved successfully: \(habit.name) with tracking mode: \(habit.trackingMode)")
            loadHabits()
            
            // If this is an automatic tracking habit, trigger immediate sync
            if trackingMode == .automatic {
                print("🔄 New automatic habit added - triggering immediate sync")
                Task {
                    await syncNewAutomaticHabit(habit)
                }
            }
        } catch {
            print("❌ Error saving habit: \(error)")
            self.error = .savingFailed(error.localizedDescription)
        }
        
        // Update notifications for the new habit
        updateNotifications()
    }
    
    // MARK: - Immediate Sync Trigger
    
    private func triggerImmediateSync() {
        // Post notification to trigger sync
        NotificationCenter.default.post(name: .immediateSync, object: nil)
    }
    
    /// Immediately sync data for a specific automatic habit that was just created
    func syncNewAutomaticHabit(_ habit: Habit) async {
        guard habit.trackingMode == .automatic else {
            print("⚠️ Cannot sync non-automatic habit: \(habit.name)")
            return
        }
        
        print("🔄 Syncing data for new automatic habit: \(habit.name)")
        
        // Post notification for immediate sync with specific habit context
        NotificationCenter.default.post(
            name: .immediateSync, 
            object: nil, 
            userInfo: ["newHabit": habit]
        )
        
        // Wait a moment for the sync to attempt, then check if we need to show a helpful message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.syncStatus == .failed(NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authorized"])) {
                print("💡 [HINT] To enable automatic tracking for '\(habit.name)', grant HealthKit permissions in Settings > Health > Data Access & Devices > WillPowr")
            }
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
            goalDescription: preset.goalDescription,
            trackingMode: preset.defaultTrackingMode,
            quitHabitType: preset.defaultQuitHabitType
        )
    }
    
    func deleteHabit(_ habit: Habit) {
        print("🗑️ HabitService: Deleting habit '\(habit.name)' (ID: \(habit.id))")
        print("🗑️ Habits before delete: \(habits.count)")
        
        modelContext.delete(habit)
        saveContext()
        loadHabits()
        
        print("🗑️ Habits after delete: \(habits.count)")
        print("🗑️ Remaining habits: \(habits.map { $0.name })")
        
        // Update notifications after deleting habit
        updateNotifications()
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
        
        // CRITICAL FIX: Save existing progress to history before resetting for new day
        if let lastCompletion = habit.lastCompletionDate,
           !Calendar.current.isDate(lastCompletion, inSameDayAs: dateManager.currentDate) {
            
            // Save previous day's progress to history before resetting
            if habit.currentProgress > 0 {
                let lastCompletionDay = Calendar.current.startOfDay(for: lastCompletion)
                print("📊 \(habit.name): Saving previous day's progress (\(habit.currentProgress)) to history for \(formatDate(lastCompletionDay))")
                createOrUpdateHistoryEntry(for: habit, on: lastCompletionDay)
            }
            
            // Now reset for the new day
            habit.currentProgress = 0
            print("📊 \(habit.name): Reset progress for new day")
        }
        
        // Handle quit habits differently
        if habit.habitType == .quit {
            handleQuitHabitProgress(habit, progress: progress)
            return
        }
        
        // Track if habit was already completed today before adding progress
        let wasAlreadyCompleted = habit.isCompleted
        
        // Add progress (don't cap at goal - let it continue beyond)
        habit.currentProgress += progress
        
        // Check if goal is met and habit wasn't already completed today
        if habit.currentProgress >= habit.goalTarget && !wasAlreadyCompleted {
            print("🎯 Goal reached! Calling markHabitComplete...")
            markHabitComplete(habit)
        } else if habit.currentProgress >= habit.goalTarget && wasAlreadyCompleted {
            print("⚠️ Goal reached but habit already completed today")
        } else {
            print("📊 Progress added but goal not yet reached: \(habit.currentProgress)/\(habit.goalTarget)")
        }
        
        // Always create or update history entry for current day's progress tracking
        createOrUpdateHistoryEntry(for: habit, on: dateManager.currentDate)
        
        saveContext()
        
        // Update notifications after progress change
        updateNotifications()
        
        // Trigger UI update
        objectWillChange.send()
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
        
        // REPLACED: Old increment/decrement logic with source-of-truth calculation
        
        // Mark as completed
        habit.isCompleted = true
        habit.lastCompletionDate = today
        
        // Create history entry for this completion FIRST
        createOrUpdateHistoryEntry(for: habit, on: today)
        
        // NEW SYSTEM: Recalculate streak from entries (source of truth)
        recalculateStreak(for: habit)
        
        print("✅ Habit marked complete: \(habit.name), Final streak: \(habit.streak), Longest ever: \(habit.longestStreak)")
        
        saveContext()
        
        // Update notifications after habit completion
        updateNotifications()
        
        // Trigger UI update
        objectWillChange.send()
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
        print("   Quit habit type: \(habit.quitHabitType.displayName)")
        print("   Previous streak: \(habit.streak)")
        print("   Last success date: \(habit.lastCompletionDate?.description ?? "none")")
        print("   Is completed: \(habit.isCompleted)")
        
        guard habit.habitType == .quit else {
            print("⚠️ Cannot mark non-quit habit as quit success")
            return
        }
        
        // Check if already marked successful today
        if let lastCompletion = habit.lastCompletionDate,
           calendar.isDate(lastCompletion, inSameDayAs: today) {
            print("⚠️ Quit habit already marked successful today, skipping")
            return
        }
        
        // Handle different quit habit types
        if habit.isAbstinenceHabit {
            // For abstinence habits, ensure no progress was recorded today
            habit.currentProgress = 0
            print("   🚫 Abstinence habit: Ensuring progress is 0")
        } else if habit.isLimitHabit {
            // For limit habits, check if under the limit
            if habit.currentProgress > habit.goalTarget {
                print("   ⚠️ Limit habit: Current progress (\(habit.currentProgress)) exceeds limit (\(habit.goalTarget))")
                print("   Cannot mark as successful while over limit")
                return
            }
            print("   ✅ Limit habit: Under limit (\(habit.currentProgress)/\(habit.goalTarget))")
        }
        
        // Mark as successful
        habit.isCompleted = true
        habit.lastCompletionDate = today
        
        // Create history entry for this success FIRST
        createOrUpdateHistoryEntry(for: habit, on: today)
        
        // NEW SYSTEM: Recalculate streak from entries (source of truth)
        recalculateStreak(for: habit)
        
        print("✅ Quit habit marked successful: \(habit.name), Final streak: \(habit.streak), Longest ever: \(habit.longestStreak)")
        
        saveContext()
        
        // Update notifications after quit habit success
        updateNotifications()
        
        // Trigger UI update by refreshing habits
        objectWillChange.send()
    }
    
    func failHabit(_ habit: Habit) {
        print("❌ Failing habit: \(habit.name)")
        print("   Quit habit type: \(habit.quitHabitType.displayName)")
        
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
        
        // Handle different quit habit types
        if habit.isAbstinenceHabit {
            // For abstinence habits, any failure resets everything
            habit.currentProgress = 1 // Mark that there was some activity
            habit.isCompleted = false
            print("   🚫 Abstinence habit failed: marked as relapsed")
        } else if habit.isLimitHabit {
            // For limit habits, failure means exceeding the limit
            if habit.currentProgress <= habit.goalTarget {
                // If currently under limit, mark as over limit
                habit.currentProgress = habit.goalTarget + 1
            }
            habit.isCompleted = false
            print("   📊 Limit habit failed: Over limit (\(habit.currentProgress)/\(habit.goalTarget))")
        }
        
        // Don't set lastCompletionDate for failures - only track successful completions
        
        // Create history entry for this failure FIRST
        createOrUpdateHistoryEntry(for: habit, on: today)
        
        // NEW SYSTEM: Recalculate streak from entries (will be 0 due to failure)
        recalculateStreak(for: habit)
        
        print("❌ Habit failed: \(habit.name), Final streak: \(habit.streak)")
        
        saveContext()
        
        // Update notifications after habit failure
        updateNotifications()
        
        // Trigger UI update by refreshing habits
        objectWillChange.send()
    }
    
    func resetHabitStreak(_ habit: Habit) {
        print("🔄 Resetting current streak for habit: \(habit.name)")
        print("   Current streak: \(habit.streak) → 0")
        print("   Longest streak remains: \(habit.longestStreak)")
        
        // Reset current state
        habit.currentProgress = 0
        habit.isCompleted = false
        habit.lastCompletionDate = nil
        
        // NEW SYSTEM: Manually set streak to 0 (this is an explicit user action)
        habit.streak = 0
        // Note: longestStreak is intentionally NOT reset - it's a historical record
        // Note: We don't recalculate from entries here because this is a manual reset
        
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
    
    // MARK: - Streak Management (New System)
    
    /// Recalculate and update streak for a habit using the new source-of-truth approach
    func recalculateStreak(for habit: Habit) {
        print("🧮 Recalculating streak for \(habit.name)")
        
        let oldCurrent = habit.streak
        let oldLongest = habit.longestStreak
        
        // Calculate new streaks from entries
        habit.streak = StreakCalculator.calculateCurrentStreak(from: habit.sortedEntries, habitType: habit.habitType)
        habit.longestStreak = StreakCalculator.calculateLongestStreak(from: habit.sortedEntries, habitType: habit.habitType)
        
        if oldCurrent != habit.streak || oldLongest != habit.longestStreak {
            print("🔄 Streak updated for \(habit.name):")
            print("   Current: \(oldCurrent) → \(habit.streak)")
            print("   Longest: \(oldLongest) → \(habit.longestStreak)")
        }
    }
    
    /// Validate and repair all habit streaks on app launch
    func validateAndRepairAllStreaks() {
        print("🔍 Validating all habit streaks...")
        var repairedCount = 0
        
        for habit in habits {
            if !StreakCalculator.validateStreak(habit: habit) {
                StreakCalculator.repairStreak(habit: habit)
                repairedCount += 1
            }
        }
        
        if repairedCount > 0 {
            print("🔧 Repaired streaks for \(repairedCount) habits")
            saveContext()
        } else {
            print("✅ All streaks are valid")
        }
    }

    // MARK: - Private Methods
    
    private func saveContext() {
        do {
            try modelContext.save()
            print("💾 Context saved successfully")
            print("💾 Current habits count after save: \(habits.count)")
        } catch {
            print("❌ Error saving context: \(error)")
            self.error = .savingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Public Save Method
    
    func saveChanges() throws {
        try modelContext.save()
        print("💾 Public save completed")
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
            // Sort by completion status (incomplete first), then by creation date (newest first)
            if habit1.isGoalMet != habit2.isGoalMet {
                return !habit1.isGoalMet && habit2.isGoalMet
            }
            return habit1.createdDate > habit2.createdDate // Newest habits appear first
        }
    }
    
    func checkForMissedDays() {
        let calendar = Calendar.current
        let today = dateManager.currentDate
        
        for habit in habits {
            guard let lastCompletion = habit.lastCompletionDate else { continue }
            
            let daysBetween = calendar.dateComponents([.day], from: lastCompletion, to: today).day ?? 0
            
            if daysBetween > 1 {
                // Missed days - reset progress and recalculate streak
                habit.currentProgress = 0
                habit.isCompleted = false
                print("📅 Reset progress for \(habit.name) due to missed days")
                
                // NEW SYSTEM: Recalculate streak from entries
                recalculateStreak(for: habit)
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
            
            // CRITICAL FIX: Check if this is a date transition and we need to save previous day's progress
            var needsHistoryForPreviousDay = false
            var previousDayDate: Date?
            
            if let lastCompletion = habit.lastCompletionDate {
                let currentDate = dateManager.currentDate
                let lastCompletionDay = Calendar.current.startOfDay(for: lastCompletion)
                let currentDay = Calendar.current.startOfDay(for: currentDate)
                
                // If last completion was on a different day than current date, we need to check if there's unsaved progress
                if !Calendar.current.isDate(lastCompletion, inSameDayAs: currentDate) {
                    // Check if we have progress that hasn't been saved to history for the last completion day
                    if previousProgress > 0 {
                        needsHistoryForPreviousDay = true
                        previousDayDate = lastCompletionDay
                        print("   📝 \(habit.name): Detected unsaved progress (\(previousProgress)) from previous day - saving to history")
                    }
                }
            } else if previousProgress > 0 {
                // No last completion but we have progress - this might be orphaned progress from a previous day
                // Save it to yesterday (best guess)
                needsHistoryForPreviousDay = true
                previousDayDate = Calendar.current.date(byAdding: .day, value: -1, to: dateManager.currentDate)
                print("   📝 \(habit.name): Detected orphaned progress (\(previousProgress)) - saving to previous day")
            }
            
            // Save previous day's progress to history before resetting
            if needsHistoryForPreviousDay, let prevDate = previousDayDate {
                // Temporarily store current values
                let tempProgress = habit.currentProgress
                let tempCompleted = habit.isCompleted
                
                // Create history entry for previous day with the existing progress
                createOrUpdateHistoryEntry(for: habit, on: prevDate)
                print("   💾 \(habit.name): Saved \(tempProgress) progress to history for \(formatDate(prevDate))")
            }
            
            // Now refresh state for the current date
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
    
    // MARK: - Quit Habit Progress Handling
    
    private func handleQuitHabitProgress(_ habit: Habit, progress: Double) {
        print("🔄 Handling quit habit progress for: \(habit.name) (\(habit.quitHabitType.displayName))")
        print("   Adding progress: \(progress)")
        print("   Current progress: \(habit.currentProgress)")
        print("   Goal target: \(habit.goalTarget)")
        
        if habit.isAbstinenceHabit {
            // For abstinence habits, any progress means failure
            habit.currentProgress += progress
            if habit.currentProgress > 0 {
                habit.isCompleted = false
                print("   🚫 Abstinence habit: Any progress means failure")
                // Create failure entry and recalculate streak
                createOrUpdateHistoryEntry(for: habit, on: dateManager.currentDate)
                recalculateStreak(for: habit)
            }
        } else if habit.isLimitHabit {
            // For limit habits, add progress and check against limit
            habit.currentProgress += progress
            
            if habit.currentProgress > habit.goalTarget {
                // Exceeded limit - this is a failure
                habit.isCompleted = false
                print("   📊 Limit exceeded: \(habit.currentProgress)/\(habit.goalTarget) - habit failed")
                // Create failure entry and recalculate streak
                createOrUpdateHistoryEntry(for: habit, on: dateManager.currentDate)
                recalculateStreak(for: habit)
            } else {
                // Still under limit - this is okay
                habit.isCompleted = false // Will be marked complete when explicitly confirmed
                print("   📊 Under limit: \(habit.currentProgress)/\(habit.goalTarget) - still successful")
            }
        }
        
        saveContext()
    }
    
    // MARK: - History Management
    
    func createOrUpdateHistoryEntry(for habit: Habit, on date: Date) {
        let targetDate = Calendar.current.startOfDay(for: date)
        
        // Check if an entry already exists for this date
        if let existingEntry = habit.entryFor(date: targetDate) {
            // Update existing entry with current habit state
            existingEntry.progress = habit.currentProgress
            existingEntry.isCompleted = habit.isCompleted
            existingEntry.goalTarget = habit.goalTarget
            existingEntry.goalUnit = habit.goalUnit
            existingEntry.habitType = habit.habitType
            existingEntry.quitHabitType = habit.quitHabitType
            print("📝 Updated history entry for \(habit.name) on \(formatDate(targetDate)): \(habit.currentProgress)")
        } else {
            // Create new entry from current habit state
            let entry = HabitEntry.createEntry(from: habit, on: targetDate)
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
            print("📝 Created new history entry for \(habit.name) on \(formatDate(targetDate)): \(habit.currentProgress)")
        }
    }
    
    // MARK: - Enhanced History Creation (for specific progress values)
    
    private func createOrUpdateHistoryEntry(for habit: Habit, on date: Date, withProgress progress: Double, completed isCompleted: Bool) {
        let targetDate = Calendar.current.startOfDay(for: date)
        
        // Check if an entry already exists for this date
        if let existingEntry = habit.entryFor(date: targetDate) {
            // Update existing entry with specific values
            existingEntry.progress = progress
            existingEntry.isCompleted = isCompleted
            existingEntry.goalTarget = habit.goalTarget
            existingEntry.goalUnit = habit.goalUnit
            existingEntry.habitType = habit.habitType
            existingEntry.quitHabitType = habit.quitHabitType
            print("📝 Updated history entry for \(habit.name) on \(formatDate(targetDate)): \(progress) (specific values)")
        } else {
            // Create new entry with specific values
            let entry = HabitEntry(
                habitId: habit.id,
                date: targetDate,
                progress: progress,
                goalTarget: habit.goalTarget,
                goalUnit: habit.goalUnit,
                habitType: habit.habitType,
                quitHabitType: habit.quitHabitType,
                isCompleted: isCompleted
            )
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
            print("📝 Created new history entry for \(habit.name) on \(formatDate(targetDate)): \(progress) (specific values)")
        }
    }
    
    func getHistoryEntries(for habit: Habit, limit: Int = 30) -> [HabitEntry] {
        return Array(habit.sortedEntries.prefix(limit))
    }
    
    func deleteHistoryEntry(_ entry: HabitEntry) {
        modelContext.delete(entry)
        saveContext()
        objectWillChange.send()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Background Sync Support
    
    func updateSyncStatus(_ status: SyncStatus) {
        syncStatus = status
        if status == .syncing {
            lastSyncTime = Date()
        }
    }
    
    func getAutomaticTrackingHabits() -> [Habit] {
        return habits.filter { $0.trackingMode == .automatic }
    }
    
    func hasAutomaticHabits() -> Bool {
        return !getAutomaticTrackingHabits().isEmpty
    }
    
    func updateHabitProgress(_ habit: Habit, progress: Double, fromBackground: Bool = false) {
        // CRITICAL FIX: Save existing progress to history before resetting for new day
        if let lastCompletion = habit.lastCompletionDate,
           !Calendar.current.isDate(lastCompletion, inSameDayAs: dateManager.currentDate) {
            
            // Save previous day's progress to history before resetting
            if habit.currentProgress > 0 {
                let lastCompletionDay = Calendar.current.startOfDay(for: lastCompletion)
                let wasCompleted = habit.currentProgress >= habit.goalTarget
                print("📊 \(habit.name): Saving previous day's progress (\(habit.currentProgress)) to history for \(formatDate(lastCompletionDay))")
                createOrUpdateHistoryEntry(for: habit, on: lastCompletionDay, withProgress: habit.currentProgress, completed: wasCompleted)
            }
            
            // Reset progress for new day
            habit.currentProgress = 0
            habit.isCompleted = false
            print("📊 \(habit.name): Reset progress for new day (background: \(fromBackground))")
        }
        
        let previousProgress = habit.currentProgress
        habit.currentProgress = progress
        
        // Check if goal was just completed
        if progress >= habit.goalTarget && !habit.isCompleted {
            if fromBackground {
                print("🎉 \(habit.name) goal completed automatically in background!")
            }
            completeHabit(habit)
        }
        
        // Always create or update history entry for current day
        createOrUpdateHistoryEntry(for: habit, on: dateManager.currentDate)
        
        // Only save if not from background (background sync will save in batch)
        if !fromBackground {
            saveContext()
            objectWillChange.send()
        }
    }
    
    // MARK: - Helper Methods
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let immediateSync = Notification.Name("immediateSync")
}

// MARK: - Habit Error

enum HabitError: Error, LocalizedError {
    case invalidName
    case duplicateHabit
    case loadingFailed(String)
    case savingFailed(String)
    case habitNotFound
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Please enter a valid habit name"
        case .duplicateHabit:
            return "A habit with this name already exists"
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

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case failed(Error)
    
    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true // Simplified comparison for errors
        default:
            return false
        }
    }
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .completed:
            return "Up to date"
        case .failed:
            return "Sync failed"
        }
    }
    
    var isActive: Bool {
        if case .syncing = self {
            return true
        }
        return false
    }
} 
