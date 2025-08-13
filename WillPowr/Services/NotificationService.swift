import Foundation
import UserNotifications
import UIKit

@MainActor
final class NotificationService: ObservableObject {
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasPermission: Bool = false
    
    // Ultra-sophisticated scheduler for dynamic notifications
    private let scheduler = NotificationScheduler()
    
    init() {
        checkPermissionStatus()
        setupAppLifecycleObservers()
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
    
    // MARK: - App Lifecycle Management
    
    private func setupAppLifecycleObservers() {
        // Observe app lifecycle events for dynamic rescheduling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // Reschedule notifications when app becomes active (handles date changes, etc.)
        if let habitService = getCurrentHabitService() {
            scheduler.scheduleNotificationsDebounced(for: habitService, delay: 0.5)
        }
    }
    
    @objc private func appWillResignActive() {
        // App about to go to background - final sync
        if let habitService = getCurrentHabitService() {
            scheduler.scheduleNotifications(for: habitService)
        }
    }
    
    @objc private func appDidEnterBackground() {
        // Schedule background refresh for notifications
        scheduleBackgroundRefresh()
    }
    
    // Helper to get current HabitService (will be set from app)
    private weak var currentHabitService: HabitService?
    
    func setHabitService(_ habitService: HabitService) {
        currentHabitService = habitService
    }
    
    private func getCurrentHabitService() -> HabitService? {
        return currentHabitService
    }
    
    // MARK: - Modern Dynamic Scheduling API
    
    /// Schedule dynamic habit reminders that update automatically
    func scheduleHabitReminders(for habitService: HabitService) {
        guard hasPermission else {
            print("❌ Cannot schedule reminders - no notification permission")
            return
        }
        
        // Set the habit service for lifecycle management
        setHabitService(habitService)
        
        // Use the sophisticated scheduler
        scheduler.scheduleNotifications(for: habitService, force: true)
    }
    
    /// Update notifications when habits change (optimized with debouncing)
    func updateNotificationsForHabitChange(_ habitService: HabitService) {
        guard hasPermission else { return }
        
        // Use debounced scheduling to avoid excessive updates
        scheduler.scheduleNotificationsDebounced(for: habitService, delay: 2.0)
    }
    
    // MARK: - Background Processing
    
    private func scheduleBackgroundRefresh() {
        // Schedule background app refresh to update notifications
        // This ensures notifications stay current even when app is backgrounded
        let identifier = "habit-notification-refresh"
        
        let request = UIApplication.shared.beginBackgroundTask(withName: identifier) {
            // Background task completion
            print("📱 Background notification refresh completed")
        }
        
        // Perform minimal background work
        Task { @MainActor [weak self] in
            if let habitService = self?.getCurrentHabitService() {
                self?.scheduler.scheduleNotifications(for: habitService)
                UIApplication.shared.endBackgroundTask(request)
            } else {
                UIApplication.shared.endBackgroundTask(request)
            }
        }
    }
    
    
    private func getIncompleteHabits(from habitService: HabitService) -> [Habit] {
        return habitService.habits.filter { habit in
            // Include all habits that aren't completed today (manual and automatic)
            !habit.isCompleted
        }
    }
    
    func clearHabitReminders() {
        // Clear all habit reminder notifications using the scheduler
        Task {
            await scheduler.clearAllNotifications()
        }
    }
    
    /// Send immediate smart notification for testing
    func sendSmartTestNotification(for habitService: HabitService) {
        guard hasPermission else {
            print("❌ No permission for smart test notification")
            return
        }
        
        let incompleteHabits = getIncompleteHabits(from: habitService)
        
        let finalTitle: String
        let finalBody: String
        
        if incompleteHabits.isEmpty {
            finalTitle = "WillPowr Smart Test 🤖"
            finalBody = "All your habits are complete! Great job 🎉"
        } else if incompleteHabits.count == 1 {
            let habit = incompleteHabits[0]
            finalTitle = "Don't break your streak! 🔥"
            finalBody = "Complete \(habit.name) to maintain your progress"
        } else {
            finalTitle = "Keep going! ⚡"
            finalBody = "You have \(incompleteHabits.count) habits waiting for you"
        }
        
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