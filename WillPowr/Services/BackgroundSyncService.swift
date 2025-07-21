import Foundation
import BackgroundTasks
import HealthKit
import SwiftUI
import Combine

@MainActor
final class BackgroundSyncService: ObservableObject {
    // MARK: - Background Task Identifiers (must match Info.plist)
    static let backgroundTaskIdentifier = "com.willpowr.background-sync"
    static let healthDataObserverIdentifier = "com.willpowr.health-observer"
    
    // MARK: - Services
    private let habitService: HabitService
    private let healthKitService: HealthKitService
    private let dateManager: DateManager
    
    // MARK: - Observer Queries
    private var observerQueries: [HKObserverQuery] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var lastBackgroundSync: Date?
    @Published var isObservingHealthChanges = false
    @Published var backgroundSyncError: Error?
    
    // MARK: - Initialization
    
    init(habitService: HabitService, healthKitService: HealthKitService, dateManager: DateManager) {
        self.habitService = habitService
        self.healthKitService = healthKitService
        self.dateManager = dateManager
        
        setupObservers()
    }
    
    deinit {
        // Clean up observers synchronously since deinit cannot be async
        let healthStore = HKHealthStore()
        for query in observerQueries {
            healthStore.stop(query)
        }
        cancellables.removeAll()
    }
    
    // MARK: - Background Task Registration
    
    func registerBackgroundTasks() {
        // Register background app refresh task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundTaskIdentifier,
            using: nil
        ) { task in
            Task {
                await self.handleBackgroundAppRefresh(task as! BGAppRefreshTask)
            }
        }
        
        print("🔴 [BG-TASK] Background task registered: \(Self.backgroundTaskIdentifier)")
    }
    
    // MARK: - Background Task Handling
    
    private func handleBackgroundAppRefresh(_ task: BGAppRefreshTask) async {
        let startTime = Date()
        print("🟦 [BACKGROUND] ========== BACKGROUND TASK STARTED ==========")
        print("🟦 [BACKGROUND] Task ID: \(Self.backgroundTaskIdentifier)")
        print("🟦 [BACKGROUND] Start time: \(DateFormatter.detailedTime.string(from: startTime))")
        
        // Schedule the next background task
        scheduleBackgroundSync()
        
        // Set expiration handler
        task.expirationHandler = {
            let elapsed = Date().timeIntervalSince(startTime)
            print("🔴 [BG-TASK] ⏰ BACKGROUND TASK EXPIRED after \(String(format: "%.1f", elapsed))s")
            print("🔴 [BG-TASK] iOS forced termination - task took too long")
            task.setTaskCompleted(success: false)
        }
        
        do {
            // Perform background sync with timeout
            let success = await performBackgroundSync()
            
            let elapsed = Date().timeIntervalSince(startTime)
            print("🟦 [BACKGROUND] ✅ Background sync completed: \(success)")
            print("🟦 [BACKGROUND] Total execution time: \(String(format: "%.1f", elapsed))s")
            print("🟦 [BACKGROUND] ========== BACKGROUND TASK ENDED ==========")
            
            task.setTaskCompleted(success: success)
            
            await MainActor.run {
                self.lastBackgroundSync = Date()
            }
            
        } catch {
            let elapsed = Date().timeIntervalSince(startTime)
            print("🔴 [BG-TASK] ❌ Background sync failed after \(String(format: "%.1f", elapsed))s: \(error)")
            print("🟦 [BACKGROUND] ========== BACKGROUND TASK ENDED (ERROR) ==========")
            await MainActor.run {
                self.backgroundSyncError = error
            }
            task.setTaskCompleted(success: false)
        }
    }
    
    private func performBackgroundSync() async -> Bool {
        print("🟡 [BG-SYNC] 🔄 Starting background health data sync...")
        
        guard healthKitService.isAuthorized else {
            print("🔴 [BG-TASK] ⚠️ HealthKit not authorized - aborting background sync")
            return false
        }
        
        let autoTrackingHabits = habitService.habits.filter { $0.trackingMode == .automatic }
        guard !autoTrackingHabits.isEmpty else {
            print("🟡 [BG-SYNC] ℹ️ No automatic habits found - background sync complete")
            return true
        }
        
        print("🟡 [BG-SYNC] Found \(autoTrackingHabits.count) automatic habits to sync:")
        for habit in autoTrackingHabits {
            print("🟡 [BG-SYNC]   • \(habit.name) (\(habit.goalUnit.displayName))")
        }
        
        var syncSuccess = true
        var habitsUpdated = 0
        
        for habit in autoTrackingHabits {
            do {
                let updated = try await syncHabitInBackground(habit)
                if updated {
                    habitsUpdated += 1
                    print("🟡 [BG-SYNC] ✅ Updated: \(habit.name)")
                } else {
                    print("🟡 [BG-SYNC] ⚪ No change: \(habit.name)")
                }
            } catch {
                print("🔴 [BG-TASK] ❌ Failed to sync \(habit.name): \(error.localizedDescription)")
                syncSuccess = false
            }
        }
        
        // Save changes
        if syncSuccess {
            do {
                try await MainActor.run {
                    try habitService.saveChanges()
                }
                print("🟡 [BG-SYNC] 💾 Saved \(habitsUpdated) habit updates to database")
            } catch {
                print("🔴 [BG-TASK] ❌ Failed to save background changes: \(error.localizedDescription)")
                syncSuccess = false
            }
        }
        
        print("🟡 [BG-SYNC] Background sync result: \(syncSuccess ? "SUCCESS" : "FAILED")")
        return syncSuccess
    }
    
    private func syncHabitInBackground(_ habit: Habit) async throws -> Bool {
        let currentDate = dateManager.currentDate
        let startTime = Date()
        
        print("🟢 [BG-HEALTH] Fetching \(habit.goalUnit.displayName) for \(habit.name)...")
        
        let progressValue: Double
        
        switch habit.goalUnit {
        case .steps:
            progressValue = try await healthKitService.getStepsForDate(currentDate)
            print("🟢 [BG-HEALTH] HealthKit returned: \(Int(progressValue)) steps")
        case .minutes:
            if habit.name.lowercased().contains("exercise") || habit.name.lowercased().contains("workout") {
                progressValue = try await healthKitService.getExerciseMinutesForDate(currentDate)
                print("🟢 [BG-HEALTH] HealthKit returned: \(Int(progressValue)) exercise minutes")
            } else if habit.name.lowercased().contains("meditat") {
                progressValue = try await healthKitService.getMindfulnessMinutesForDate(currentDate)
                print("🟢 [BG-HEALTH] HealthKit returned: \(Int(progressValue)) mindfulness minutes")
            } else {
                progressValue = try await healthKitService.getExerciseMinutesForDate(currentDate)
                print("🟢 [BG-HEALTH] HealthKit returned: \(Int(progressValue)) minutes (default to exercise)")
            }
        default:
            print("🔴 [BG-TASK] ⚠️ Unsupported goal unit for background sync: \(habit.goalUnit)")
            return false
        }
        
        let fetchTime = Date().timeIntervalSince(startTime)
        print("🟢 [BG-HEALTH] Health data fetch took \(String(format: "%.2f", fetchTime))s")
        
        let wasUpdated = await MainActor.run {
            let previousProgress = habit.currentProgress
            let goalTarget = habit.goalTarget
            let wasCompleted = habit.isCompleted
            
            // Update progress
            habit.currentProgress = progressValue
            
            // Check if goal was completed
            if progressValue >= goalTarget && !wasCompleted {
                habitService.completeHabit(habit)
                print("🟡 [BG-SYNC] 🎉 \(habit.name) goal completed in background! (\(Int(progressValue))/\(Int(goalTarget)))")
                return true
            } else if abs(progressValue - previousProgress) >= 1.0 {
                print("🟡 [BG-SYNC] Progress updated: \(habit.name) \(Int(previousProgress)) → \(Int(progressValue))")
                return true
            } else {
                print("🟡 [BG-SYNC] No significant change: \(habit.name) (\(Int(progressValue))/\(Int(goalTarget)))")
                return false
            }
        }
        
        return wasUpdated
    }
    
    // MARK: - Background Task Scheduling
    
    func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundTaskIdentifier)
        
        // Schedule for 15 minutes from now (iOS will adjust based on usage patterns)
        let scheduleTime = Date(timeIntervalSinceNow: 15 * 60)
        request.earliestBeginDate = scheduleTime
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("🔴 [BG-TASK] 📅 Background sync scheduled for: \(DateFormatter.detailedTime.string(from: scheduleTime))")
            print("🔴 [BG-TASK] ℹ️ Actual execution depends on iOS usage patterns")
        } catch {
            print("🔴 [BG-TASK] ❌ Could not schedule background sync: \(error.localizedDescription)")
            // Don't throw here - just log the error
        }
    }
    
    // MARK: - HealthKit Observer Queries
    
    func startObservingHealthChanges() {
        print("🟢 [BG-HEALTH] 👀 Starting HealthKit observer setup...")
        
        guard healthKitService.isAuthorized else {
            print("🔴 [BG-TASK] ⚠️ HealthKit not authorized - cannot start health observers")
            return
        }
        
        stopObservingHealthChanges() // Clean up existing observers
        
        let typesToObserve = getHealthTypesToObserve()
        print("🟢 [BG-HEALTH] Found \(typesToObserve.count) health types to observe:")
        
        for healthType in typesToObserve {
            print("🟢 [BG-HEALTH]   • \(healthType.identifier)")
            
            let observerQuery = HKObserverQuery(sampleType: healthType, predicate: nil) { [weak self] query, completionHandler, error in
                
                if let error = error {
                    print("🔴 [BG-TASK] ❌ Health observer error for \(healthType.identifier): \(error.localizedDescription)")
                    return
                }
                
                print("🟢 [BG-HEALTH] 🔔 REAL-TIME HEALTH UPDATE: \(healthType.identifier)")
                print("🟢 [BG-HEALTH] ⚡ Triggering immediate background sync...")
                
                Task { @MainActor in
                    await self?.handleHealthDataChange(for: healthType)
                }
                
                // Must call completion handler
                completionHandler()
            }
            
            // Enable background delivery
            let healthStore = HKHealthStore()
            healthStore.enableBackgroundDelivery(for: healthType, frequency: .immediate) { success, error in
                if success {
                    print("🟢 [BG-HEALTH] ✅ Background delivery enabled for \(healthType.identifier)")
                } else {
                    print("🔴 [BG-TASK] ❌ Failed to enable background delivery for \(healthType.identifier): \(error?.localizedDescription ?? "unknown")")
                }
            }
            
            healthStore.execute(observerQuery)
            observerQueries.append(observerQuery)
        }
        
        isObservingHealthChanges = true
        print("🟢 [BG-HEALTH] ✅ Observer setup complete - watching \(observerQueries.count) health data types")
        print("🟢 [BG-HEALTH] 🔔 Ready for real-time health updates!")
    }
    
    func stopObservingHealthChanges() {
        print("🟢 [BG-HEALTH] 🛑 Stopping health observers...")
        
        let healthStore = HKHealthStore()
        
        // Stop all observer queries
        for query in observerQueries {
            healthStore.stop(query)
        }
        print("🟢 [BG-HEALTH] Stopped \(observerQueries.count) observer queries")
        observerQueries.removeAll()
        
        // Disable background delivery for the types we were observing
        let typesToObserve = getHealthTypesToObserve()
        for healthType in typesToObserve {
            healthStore.disableBackgroundDelivery(for: healthType) { success, error in
                if !success {
                    print("🔴 [BG-TASK] ⚠️ Failed to disable background delivery for \(healthType.identifier): \(error?.localizedDescription ?? "unknown")")
                } else {
                    print("🟢 [BG-HEALTH] Background delivery disabled for \(healthType.identifier)")
                }
            }
        }
        
        isObservingHealthChanges = false
        print("🟢 [BG-HEALTH] ✅ Health observer cleanup complete")
    }
    
    private func getHealthTypesToObserve() -> [HKSampleType] {
        var types: [HKSampleType] = []
        
        // Add types based on what automatic habits need
        let autoHabits = habitService.habits.filter { $0.trackingMode == .automatic }
        
        for habit in autoHabits {
            switch habit.goalUnit {
            case .steps:
                if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
                    types.append(stepCount)
                }
            case .minutes:
                if habit.name.lowercased().contains("exercise") || habit.name.lowercased().contains("workout") {
                    if let exerciseTime = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
                        types.append(exerciseTime)
                    }
                } else if habit.name.lowercased().contains("meditat") {
                    if let mindfulSession = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
                        types.append(mindfulSession)
                    }
                }
            default:
                break
            }
        }
        
        return Array(Set(types)) // Remove duplicates
    }
    
    private func handleHealthDataChange(for healthType: HKSampleType) async {
        let startTime = Date()
        print("🟢 [BG-HEALTH] ⚡ PROCESSING REAL-TIME UPDATE for \(healthType.identifier)")
        
        // Find habits that use this health data type
        let relevantHabits = habitService.habits.filter { habit in
            guard habit.trackingMode == .automatic else { return false }
            
            switch habit.goalUnit {
            case .steps:
                return healthType.identifier == HKQuantityTypeIdentifier.stepCount.rawValue
            case .minutes:
                if habit.name.lowercased().contains("exercise") || habit.name.lowercased().contains("workout") {
                    return healthType.identifier == HKQuantityTypeIdentifier.appleExerciseTime.rawValue
                } else if habit.name.lowercased().contains("meditat") {
                    return healthType.identifier == HKCategoryTypeIdentifier.mindfulSession.rawValue
                }
                return false
            default:
                return false
            }
        }
        
        guard !relevantHabits.isEmpty else {
            print("🟢 [BG-HEALTH] ℹ️ No relevant habits for \(healthType.identifier) - ignoring update")
            return
        }
        
        print("🟢 [BG-HEALTH] 🎯 Found \(relevantHabits.count) habits affected by \(healthType.identifier) change:")
        for habit in relevantHabits {
            print("🟢 [BG-HEALTH]   • \(habit.name)")
        }
        
        var updatedCount = 0
        
        // Sync the relevant habits
        for habit in relevantHabits {
            do {
                let wasUpdated = try await syncHabitInBackground(habit)
                if wasUpdated {
                    updatedCount += 1
                }
            } catch {
                print("🔴 [BG-TASK] ❌ Failed to update \(habit.name) from health change: \(error.localizedDescription)")
            }
        }
        
        // Save changes
        do {
            try habitService.saveChanges()
            let elapsed = Date().timeIntervalSince(startTime)
            print("🟢 [BG-HEALTH] 💾 Real-time sync complete: \(updatedCount) habits updated in \(String(format: "%.2f", elapsed))s")
        } catch {
            print("🔴 [BG-TASK] ❌ Failed to save real-time updates: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Setup and Lifecycle
    
    private func setupObservers() {
        // Listen for authorization changes
        healthKitService.$isAuthorized
            .sink { [weak self] isAuthorized in
                if isAuthorized {
                    Task { @MainActor in
                        self?.startObservingHealthChanges()
                        self?.scheduleBackgroundSync()
                    }
                } else {
                    self?.stopObservingHealthChanges()
                }
            }
            .store(in: &cancellables)
        
        // Listen for app going to background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.scheduleBackgroundSync()
            }
            .store(in: &cancellables)
        
        // Listen for app becoming active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                // Refresh observer queries when app becomes active
                if self?.healthKitService.isAuthorized == true {
                    self?.startObservingHealthChanges()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    func initialize() async {
        registerBackgroundTasks()
        
        if healthKitService.isAuthorized {
            startObservingHealthChanges()
            scheduleBackgroundSync()
        }
    }
    
    func refreshHealthObservers() {
        if healthKitService.isAuthorized {
            startObservingHealthChanges()
        }
    }
    
    // MARK: - Debug Information
    
    func getBackgroundSyncStatus() -> String {
        var status = "Background Sync Status:\n"
        status += "• Health observers: \(isObservingHealthChanges ? "Active" : "Inactive")\n"
        status += "• Observer count: \(observerQueries.count)\n"
        
        if let lastSync = lastBackgroundSync {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            status += "• Last background sync: \(formatter.string(from: lastSync))\n"
        } else {
            status += "• Last background sync: Never\n"
        }
        
        if let error = backgroundSyncError {
            status += "• Last error: \(error.localizedDescription)\n"
        }
        
        return status
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let detailedTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Background Task Error

enum BackgroundSyncError: LocalizedError {
    case notAuthorized
    case noAutoHabits
    case healthKitFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit authorization required for background sync"
        case .noAutoHabits:
            return "No automatic tracking habits found"
        case .healthKitFailed(let message):
            return "HealthKit sync failed: \(message)"
        case .saveFailed(let message):
            return "Failed to save background changes: \(message)"
        }
    }
}