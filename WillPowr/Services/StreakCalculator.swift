import Foundation

/// A robust streak calculation system that derives streaks from historical entries
/// This ensures streaks are always accurate regardless of app crashes, background sync, or timezone changes
class StreakCalculator {
    
    // MARK: - Date Helpers (Timezone Safe)
    
    /// Get the start of day in user's current timezone
    private static func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    /// Calculate days between two dates (timezone safe)
    private static func daysBetween(_ date1: Date, _ date2: Date) -> Int {
        let day1 = startOfDay(for: date1)
        let day2 = startOfDay(for: date2)
        return Calendar.current.dateComponents([.day], from: day1, to: day2).day ?? 0
    }
    
    /// Check if a date is today (timezone safe)
    private static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Get yesterday's date (timezone safe)
    private static func yesterday() -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    }
    
    // MARK: - Core Streak Calculations
    
    /// Calculate current streak from entries (source of truth)
    static func calculateCurrentStreak(from entries: [HabitEntry], habitType: HabitType) -> Int {
        // Sort entries by date (most recent first)
        let sortedEntries = entries.sorted { $0.date > $1.date }
        
        print("🧮 Calculating current streak from \(sortedEntries.count) entries")
        
        var streak = 0
        var currentDate = startOfDay(for: Date())
        
        // Start from today and work backwards
        while true {
            let entryForDay = sortedEntries.first { entry in
                startOfDay(for: entry.date) == currentDate
            }
            
            if let entry = entryForDay {
                // Check if this day was successful
                if isSuccessfulDay(entry: entry, habitType: habitType) {
                    streak += 1
                    print("   ✅ \(formatDate(currentDate)): Success (streak: \(streak))")
                } else {
                    print("   ❌ \(formatDate(currentDate)): Failed - streak broken")
                    break
                }
            } else {
                // No entry for this day
                if Calendar.current.isDateInToday(currentDate) {
                    // Today with no entry - if it's not yet end of day, don't break streak
                    let now = Date()
                    let endOfToday = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: currentDate) ?? currentDate
                    
                    if now < endOfToday {
                        // Still time left today, don't count as missed yet
                        print("   ⏳ \(formatDate(currentDate)): Today with no entry yet - continuing")
                    } else {
                        print("   ❌ \(formatDate(currentDate)): No entry - streak broken")
                        break
                    }
                } else {
                    // Past day with no entry - streak broken
                    print("   ❌ \(formatDate(currentDate)): No entry - streak broken")
                    break
                }
            }
            
            // Move to previous day
            guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
            
            // Safety: don't go back more than a reasonable time (e.g., 1000 days)
            if streak > 1000 {
                print("⚠️ Streak calculation exceeded 1000 days - stopping for safety")
                break
            }
        }
        
        print("🏁 Final current streak: \(streak)")
        return streak
    }
    
    /// Calculate longest streak from all entries
    static func calculateLongestStreak(from entries: [HabitEntry], habitType: HabitType) -> Int {
        // Sort entries by date (oldest first for this calculation)
        let sortedEntries = entries.sorted { $0.date < $1.date }
        
        print("🏆 Calculating longest streak from \(sortedEntries.count) entries")
        
        var longestStreak = 0
        var currentStreak = 0
        var lastSuccessDate: Date?
        
        for entry in sortedEntries {
            let entryDate = startOfDay(for: entry.date)
            
            if isSuccessfulDay(entry: entry, habitType: habitType) {
                if let lastDate = lastSuccessDate {
                    let daysBetween = daysBetween(lastDate, entryDate)
                    
                    if daysBetween == 1 {
                        // Consecutive day
                        currentStreak += 1
                    } else if daysBetween > 1 {
                        // Gap - restart streak
                        longestStreak = max(longestStreak, currentStreak)
                        currentStreak = 1
                    }
                    // daysBetween == 0 means same day, keep current streak
                } else {
                    // First successful day
                    currentStreak = 1
                }
                lastSuccessDate = entryDate
            } else {
                // Failed day - update longest if needed and reset current
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 0
                lastSuccessDate = nil
            }
        }
        
        // Final check
        longestStreak = max(longestStreak, currentStreak)
        
        print("🏁 Longest streak ever: \(longestStreak)")
        return longestStreak
    }
    
    // MARK: - Success Determination
    
    /// Determine if an entry represents a successful day for the habit
    private static func isSuccessfulDay(entry: HabitEntry, habitType: HabitType) -> Bool {
        switch habitType {
        case .build:
            // Build habits: must meet goal or be marked complete
            if entry.goalUnit == .none {
                // Binary habit - check completion flag
                return entry.isCompleted
            } else {
                // Goal-based habit - check if goal was met
                return entry.progress >= entry.goalTarget || entry.isCompleted
            }
            
        case .quit:
            // Quit habits: must be marked as successful (stayed clean/under limit)
            return entry.isCompleted
        }
    }
    
    // MARK: - Validation & Repair
    
    /// Validate that a habit's stored streak matches calculated streak
    static func validateStreak(habit: Habit) -> Bool {
        let calculatedCurrent = calculateCurrentStreak(from: habit.sortedEntries, habitType: habit.habitType)
        let calculatedLongest = calculateLongestStreak(from: habit.sortedEntries, habitType: habit.habitType)
        
        let currentMatches = habit.streak == calculatedCurrent
        let longestMatches = habit.longestStreak == calculatedLongest
        
        if !currentMatches || !longestMatches {
            print("⚠️ Streak validation failed for \(habit.name):")
            print("   Current: stored=\(habit.streak), calculated=\(calculatedCurrent)")
            print("   Longest: stored=\(habit.longestStreak), calculated=\(calculatedLongest)")
            return false
        }
        
        return true
    }
    
    /// Repair a habit's streak data based on entries
    static func repairStreak(habit: Habit) {
        print("🔧 Repairing streak for \(habit.name)")
        
        let oldCurrent = habit.streak
        let oldLongest = habit.longestStreak
        
        habit.streak = calculateCurrentStreak(from: habit.sortedEntries, habitType: habit.habitType)
        habit.longestStreak = calculateLongestStreak(from: habit.sortedEntries, habitType: habit.habitType)
        
        print("   Current: \(oldCurrent) → \(habit.streak)")
        print("   Longest: \(oldLongest) → \(habit.longestStreak)")
        print("✅ Streak repaired for \(habit.name)")
    }
    
    // MARK: - Helper Methods
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Get streak history for visualization (used by contribution grid)
    static func getStreakHistory(from entries: [HabitEntry], habitType: HabitType, days: Int = 90) -> [Date: Bool] {
        var history: [Date: Bool] = [:]
        let today = Date()
        
        for i in 0..<days {
            guard let date = Calendar.current.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayStart = startOfDay(for: date)
            
            let entryForDay = entries.first { entry in
                startOfDay(for: entry.date) == dayStart
            }
            
            if let entry = entryForDay {
                history[dayStart] = isSuccessfulDay(entry: entry, habitType: habitType)
            } else {
                history[dayStart] = false
            }
        }
        
        return history
    }
}