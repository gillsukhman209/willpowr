import Foundation
import UserNotifications
import UIKit

/// Ultra-sophisticated notification scheduler that ensures notifications are always accurate
/// and dynamically updated based on current habit state
@MainActor
final class NotificationScheduler: ObservableObject {
    
    // MARK: - State Management
    
    private struct ScheduledState: Codable {
        let incompleteHabitIds: Set<UUID>
        let scheduledDate: Date
        let timeSlots: Set<String>
        
        func matches(currentHabits: [Habit], for date: Date) -> Bool {
            let currentIncompleteIds = Set(currentHabits.filter { !$0.isCompleted }.map { $0.id })
            let isSameDate = Calendar.current.isDate(scheduledDate, inSameDayAs: date)
            return incompleteHabitIds == currentIncompleteIds && isSameDate
        }
    }
    
    private var lastScheduledState: ScheduledState?
    private var debounceTimer: Timer?
    private var isRescheduling = false
    
    // MARK: - Time Slots Configuration
    
    enum TimeSlot: String, CaseIterable {
        case morning = "morning"
        case afternoon = "afternoon" 
        case evening = "evening"
        case night = "night"
        
        var hour: Int {
            switch self {
            case .morning: return 9    // 9:00 AM
            case .afternoon: return 14 // 2:00 PM  
            case .evening: return 18   // 6:00 PM
            case .night: return 21     // 9:00 PM
            }
        }
        
        var displayName: String {
            switch self {
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening" 
            case .night: return "Night"
            }
        }
        
        var notificationId: String {
            return "habit-reminder-\(self.rawValue)"
        }
    }
    
    // MARK: - Public Interface
    
    /// Schedule or reschedule notifications based on current habit state
    func scheduleNotifications(for habitService: HabitService, force: Bool = false) {
        // Prevent recursive calls
        guard !isRescheduling else { return }
        
        let currentHabits = habitService.habits
        let today = Date()
        
        // Check if we need to reschedule
        if !force && !needsRescheduling(for: currentHabits, date: today) {
            print("📅 Notifications already up-to-date, skipping reschedule")
            return
        }
        
        isRescheduling = true
        print("📅 Scheduling dynamic notifications for today...")
        
        Task {
            await performScheduling(for: habitService)
            await MainActor.run {
                self.isRescheduling = false
            }
        }
    }
    
    /// Schedule notifications with debouncing to prevent excessive rescheduling
    func scheduleNotificationsDebounced(for habitService: HabitService, delay: TimeInterval = 1.0) {
        debounceTimer?.invalidate()
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleNotifications(for: habitService)
            }
        }
    }
    
    /// Clear all habit reminder notifications
    func clearAllNotifications() async {
        let identifiers = TimeSlot.allCases.map { $0.notificationId }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        lastScheduledState = nil
        print("🧹 Cleared all habit reminder notifications")
    }
    
    // MARK: - Core Scheduling Logic
    
    private func performScheduling(for habitService: HabitService) async {
        let incompleteHabits = getIncompleteHabits(from: habitService)
        let today = Date()
        
        // Clear existing notifications first
        await clearAllNotifications()
        
        // If no incomplete habits, we're done
        guard !incompleteHabits.isEmpty else {
            print("✅ All habits complete - no notifications needed")
            return
        }
        
        // Schedule notifications for each time slot
        var scheduledSlots: Set<String> = []
        
        for timeSlot in TimeSlot.allCases {
            let success = await scheduleNotificationForTimeSlot(
                timeSlot, 
                incompleteHabits: incompleteHabits, 
                today: today
            )
            if success {
                scheduledSlots.insert(timeSlot.rawValue)
            }
        }
        
        // Update our state tracking
        lastScheduledState = ScheduledState(
            incompleteHabitIds: Set(incompleteHabits.map { $0.id }),
            scheduledDate: today,
            timeSlots: scheduledSlots
        )
        
        print("✅ Scheduled notifications for \(scheduledSlots.count) time slots")
    }
    
    private func scheduleNotificationForTimeSlot(
        _ timeSlot: TimeSlot, 
        incompleteHabits: [Habit], 
        today: Date
    ) async -> Bool {
        let content = generateNotificationContent(
            for: incompleteHabits, 
            timeSlot: timeSlot, 
            today: today
        )
        
        // Skip if no content to show
        guard !content.title.isEmpty && !content.body.isEmpty else {
            print("ℹ️ Skipping \(timeSlot.displayName) - no relevant content")
            return false
        }
        
        // Calculate the exact delivery time for today
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: today)
        dateComponents.hour = timeSlot.hour
        dateComponents.minute = 0
        dateComponents.second = 0
        
        guard let deliveryDate = Calendar.current.date(from: dateComponents) else {
            print("❌ Could not create delivery date for \(timeSlot.displayName)")
            return false
        }
        
        // Skip if the time has already passed today
        if deliveryDate < Date() {
            print("ℹ️ Skipping \(timeSlot.displayName) - time already passed today")
            return false
        }
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.sound = .default
        notificationContent.badge = incompleteHabits.count as NSNumber
        notificationContent.categoryIdentifier = "HABIT_REMINDER"
        notificationContent.userInfo = [
            "timeSlot": timeSlot.rawValue,
            "habitIds": incompleteHabits.map { $0.id.uuidString },
            "scheduledDate": ISO8601DateFormatter().string(from: today)
        ]
        
        // Create trigger for the specific time today (no repeating)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: timeSlot.notificationId,
            content: notificationContent,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Scheduled \(timeSlot.displayName) notification for \(formatTime(deliveryDate))")
            return true
        } catch {
            print("❌ Error scheduling \(timeSlot.displayName) notification: \(error)")
            return false
        }
    }
    
    // MARK: - Content Generation
    
    private struct NotificationContent {
        let title: String
        let body: String
    }
    
    private func generateNotificationContent(
        for habits: [Habit], 
        timeSlot: TimeSlot, 
        today: Date
    ) -> NotificationContent {
        
        // No habits - no notification
        guard !habits.isEmpty else {
            return NotificationContent(title: "", body: "")
        }
        
        let title = generateTitle(for: habits, timeSlot: timeSlot)
        let body = generateBody(for: habits, timeSlot: timeSlot)
        
        return NotificationContent(title: title, body: body)
    }
    
    private func generateTitle(for habits: [Habit], timeSlot: TimeSlot) -> String {
        if habits.count == 1 {
            let habit = habits[0]
            if habit.streak > 0 {
                return "Don't break your \(habit.streak)-day streak! 🔥"
            } else {
                return "Start building your streak! 💪"
            }
        } else {
            switch timeSlot {
            case .morning:
                return "Start your day strong! 🌅"
            case .afternoon:
                return "Midday momentum check! ⚡"
            case .evening:
                return "Keep your streak alive! 🔥"
            case .night:
                return "Last chance to succeed! ⏰"
            }
        }
    }
    
    private func generateBody(for habits: [Habit], timeSlot: TimeSlot) -> String {
        if habits.count == 1 {
            let habit = habits[0]
            return generateSingleHabitMessage(habit: habit, timeSlot: timeSlot)
        } else {
            return generateMultipleHabitsMessage(habits: habits, timeSlot: timeSlot)
        }
    }
    
    private func generateSingleHabitMessage(habit: Habit, timeSlot: TimeSlot) -> String {
        let baseMessage: String
        
        if habit.streak >= 7 {
            baseMessage = "Complete \(habit.name) to keep your amazing \(habit.streak)-day streak going"
        } else if habit.streak > 0 {
            baseMessage = "Complete \(habit.name) to maintain your \(habit.streak)-day streak"
        } else {
            baseMessage = "Time to complete \(habit.name) and start building momentum"
        }
        
        let timeMotivation = getTimeSpecificMotivation(timeSlot: timeSlot)
        return "\(baseMessage). \(timeMotivation)"
    }
    
    private func generateMultipleHabitsMessage(habits: [Habit], timeSlot: TimeSlot) -> String {
        let habitCount = habits.count
        
        let baseMessage: String
        if habitCount <= 3 {
            let habitNames = habits.map { $0.name }.joined(separator: ", ")
            baseMessage = "You have \(habitCount) habits waiting: \(habitNames)"
        } else {
            let firstThree = habits.prefix(3).map { $0.name }.joined(separator: ", ")
            baseMessage = "You have \(habitCount) habits waiting: \(firstThree) and \(habitCount - 3) more"
        }
        
        let timeMotivation = getTimeSpecificMotivation(timeSlot: timeSlot)
        return "\(baseMessage). \(timeMotivation)"
    }
    
    private func getTimeSpecificMotivation(timeSlot: TimeSlot) -> String {
        switch timeSlot {
        case .morning:
            return "Start strong and set the tone for your day!"
        case .afternoon:
            return "You've got this - keep the momentum going!"
        case .evening:
            return "Don't let today slip away!"
        case .night:
            return "Last chance to make today count!"
        }
    }
    
    // MARK: - Helper Methods
    
    private func getIncompleteHabits(from habitService: HabitService) -> [Habit] {
        return habitService.habits.filter { !$0.isCompleted }
    }
    
    private func needsRescheduling(for habits: [Habit], date: Date) -> Bool {
        guard let lastState = lastScheduledState else { return true }
        return !lastState.matches(currentHabits: habits, for: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}