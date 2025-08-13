import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationService: ObservableObject {
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasPermission: Bool = false
    
    init() {
        checkPermissionStatus()
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async -> Bool {
        print("🔔 Requesting notification permission...")
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await MainActor.run {
                self.hasPermission = granted
                print("🔔 Permission granted: \(granted)")
            }
            
            // Update status after requesting
            await checkPermissionStatus()
            
            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            await MainActor.run {
                self.hasPermission = false
            }
            return false
        }
    }
    
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        await MainActor.run {
            self.permissionStatus = settings.authorizationStatus
            self.hasPermission = settings.authorizationStatus == .authorized
            
            print("🔔 Notification permission status: \(settings.authorizationStatus.rawValue)")
        }
    }
    
    private func checkPermissionStatus() {
        Task {
            await checkPermissionStatus()
        }
    }
    
    // MARK: - Test Notifications
    
    func sendTestNotification() {
        guard hasPermission else {
            print("❌ No notification permission - requesting...")
            Task {
                await requestPermission()
            }
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "WillPowr Test 🔥"
        content.body = "Notifications are working! Your habits are waiting for you."
        content.sound = .default
        content.badge = 1
        
        // Send immediately
        let request = UNNotificationRequest(
            identifier: "test-notification-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending test notification: \(error)")
            } else {
                print("✅ Test notification scheduled successfully")
            }
        }
    }
    
    func sendDelayedTestNotification(delay: TimeInterval = 5) {
        guard hasPermission else {
            print("❌ No notification permission for delayed test")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "WillPowr Delayed Test ⏰"
        content.body = "This notification was scheduled \(Int(delay)) seconds ago!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "delayed-test-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending delayed test notification: \(error)")
            } else {
                print("✅ Delayed test notification scheduled for \(Int(delay)) seconds")
            }
        }
    }
    
    // MARK: - Smart Habit Reminders
    
    enum TimeSlot: CaseIterable {
        case morning, afternoon, evening, night
        
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
    }
    
    func scheduleHabitReminders(for habitService: HabitService) {
        guard hasPermission else {
            print("❌ Cannot schedule reminders - no notification permission")
            return
        }
        
        print("📅 Scheduling daily habit reminders...")
        
        // Clear existing habit reminders
        clearHabitReminders()
        
        // Schedule for each time slot
        for timeSlot in TimeSlot.allCases {
            scheduleReminderForTimeSlot(timeSlot, habitService: habitService)
        }
        
        print("✅ Scheduled reminders for all time slots")
    }
    
    private func scheduleReminderForTimeSlot(_ timeSlot: TimeSlot, habitService: HabitService) {
        // Generate smart content based on habits
        let (title, body) = generateSmartNotificationContent(
            timeSlot: timeSlot,
            habitService: habitService
        )
        
        // Skip scheduling if no content (all habits completed)
        guard !title.isEmpty && !body.isEmpty else {
            print("ℹ️ Skipping \(timeSlot.displayName) reminder - no incomplete habits")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = ["timeSlot": timeSlot.displayName]
        
        // Create daily repeating trigger
        var dateComponents = DateComponents()
        dateComponents.hour = timeSlot.hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "habit-reminder-\(timeSlot.displayName.lowercased())",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling \(timeSlot.displayName) reminder: \(error)")
            } else {
                print("✅ Scheduled \(timeSlot.displayName) reminder for \(timeSlot.hour):00")
            }
        }
    }
    
    private func generateSmartNotificationContent(timeSlot: TimeSlot, habitService: HabitService) -> (String, String) {
        let incompleteHabits = getIncompleteHabits(from: habitService)
        
        // No incomplete habits - don't send notification
        guard !incompleteHabits.isEmpty else {
            return ("", "") // Empty content will prevent notification
        }
        
        let title = generateTitle(for: incompleteHabits, timeSlot: timeSlot)
        let body = generateBody(for: incompleteHabits, timeSlot: timeSlot)
        
        return (title, body)
    }
    
    private func getIncompleteHabits(from habitService: HabitService) -> [Habit] {
        return habitService.habits.filter { habit in
            // Include all habits that aren't completed today (manual and automatic)
            !habit.isCompleted
        }
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
        
        // Add time-specific motivation
        let timeMotivation = getTimeSpecificMotivation(timeSlot: timeSlot)
        return "\(baseMessage). \(timeMotivation)"
    }
    
    private func generateMultipleHabitsMessage(habits: [Habit], timeSlot: TimeSlot) -> String {
        let habitCount = habits.count
        let habitNames = habits.prefix(3).map { $0.name }.joined(separator: ", ")
        
        let baseMessage: String
        if habitCount <= 3 {
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
    
    func clearHabitReminders() {
        let identifiers = TimeSlot.allCases.map { "habit-reminder-\($0.displayName.lowercased())" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("🧹 Cleared existing habit reminders")
    }
    
    /// Send immediate smart notification for testing
    func sendSmartTestNotification(for habitService: HabitService) {
        guard hasPermission else {
            print("❌ No permission for smart test notification")
            return
        }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        let timeSlot: TimeSlot
        
        // Determine current time slot
        switch currentHour {
        case 0..<12:
            timeSlot = .morning
        case 12..<16:
            timeSlot = .afternoon
        case 16..<20:
            timeSlot = .evening
        default:
            timeSlot = .night
        }
        
        let (title, body) = generateSmartNotificationContent(
            timeSlot: timeSlot,
            habitService: habitService
        )
        
        // If no incomplete habits, send a different test message
        let finalTitle = title.isEmpty ? "WillPowr Smart Test 🤖" : title
        let finalBody = body.isEmpty ? "All your habits are complete! Great job 🎉" : body
        
        let content = UNMutableNotificationContent()
        content.title = finalTitle
        content.body = finalBody
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "smart-test-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending smart test notification: \(error)")
            } else {
                print("✅ Smart test notification sent: \(finalTitle)")
            }
        }
    }

    // MARK: - Utility
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Clear badge (iOS 16+)
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        print("🧹 All notifications cleared")
    }
    
    func openNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Permission Status Extension

extension UNAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}