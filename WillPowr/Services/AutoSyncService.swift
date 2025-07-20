import Foundation
import SwiftUI
import Combine

@MainActor
final class AutoSyncService: ObservableObject {
    private let habitService: HabitService
    private let healthKitService: HealthKitService
    private let dateManager: DateManager
    
    @Published var isAutoSyncEnabled = true
    @Published var lastSyncTime: Date?
    @Published var syncError: Error?
    
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Sync frequency in seconds (2 minutes for very frequent updates)
    private let syncInterval: TimeInterval = 120
    
    init(habitService: HabitService, healthKitService: HealthKitService, dateManager: DateManager) {
        self.habitService = habitService
        self.healthKitService = healthKitService
        self.dateManager = dateManager
        
        setupAutoSync()
    }
    
    deinit {
        // Clean up timer synchronously since it needs to be done immediately
        if let timer = syncTimer {
            timer.invalidate()
        }
        cancellables.removeAll()
    }
    
    // MARK: - Auto Sync Management
    
    private func setupAutoSync() {
        // Start auto sync timer
        startAutoSync()
        
        // Listen for app becoming active (coming from background or launching)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                print("📱 App became active - syncing health data")
                Task { @MainActor in
                    await self?.syncAllHabits()
                }
            }
            .store(in: &cancellables)
            
        // Listen for app entering foreground (more specific than didBecomeActive)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                print("📱 App entering foreground - syncing health data")
                Task { @MainActor in
                    await self?.syncAllHabits()
                }
            }
            .store(in: &cancellables)
            
        // Listen for app going to background (to clean up resources if needed)
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                print("📱 App entering background")
                // Could add cleanup logic here if needed
            }
            .store(in: &cancellables)
        
        // Listen for immediate sync requests (when new automatic habits are added)
        NotificationCenter.default.publisher(for: .immediateSync)
            .sink { [weak self] _ in
                Task { @MainActor in
                    print("🔄 Immediate sync requested - syncing now")
                    await self?.syncAllHabits()
                }
            }
            .store(in: &cancellables)
        
        // Listen for HealthKit authorization changes
        healthKitService.$isAuthorized
            .sink { [weak self] isAuthorized in
                print("🔄 HealthKit authorization changed: \(isAuthorized)")
                if isAuthorized {
                    Task { @MainActor in
                        print("✅ HealthKit authorized - starting immediate sync")
                        await self?.syncAllHabits()
                    }
                } else {
                    print("⚠️ HealthKit not authorized - auto habits will need manual input")
                    // Don't automatically switch to manual - let user decide
                }
            }
            .store(in: &cancellables)
    }
    
    func startAutoSync() {
        guard isAutoSyncEnabled else { return }
        
        stopAutoSync() // Stop existing timer
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncAllHabits()
            }
        }
        
        print("🔄 AutoSync started - will sync every \(Int(syncInterval / 60)) minutes (\(Int(syncInterval))s)")
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("⏹️ AutoSync stopped")
    }
    
    func toggleAutoSync() {
        isAutoSyncEnabled.toggle()
        if isAutoSyncEnabled {
            startAutoSync()
        } else {
            stopAutoSync()
        }
    }
    
    // MARK: - Sync Methods
    
    func syncAllHabits() async {
        print("🔄 syncAllHabits called - HealthKit authorized: \(healthKitService.isAuthorized)")
        
        guard healthKitService.isAuthorized else {
            print("⚠️ HealthKit not authorized - skipping auto sync")
            return
        }
        
        // Check if we've synced recently (unless it's a force sync)
        if let lastSync = lastSyncTime,
           Date().timeIntervalSince(lastSync) < 30 { // 30 seconds minimum between syncs
            print("⏳ Last sync was \(Int(Date().timeIntervalSince(lastSync))) seconds ago - skipping duplicate sync")
            return
        }
        
        let autoTrackingHabits = habitService.habits.filter { $0.trackingMode == .automatic }
        
        guard !autoTrackingHabits.isEmpty else {
            print("ℹ️ No habits using automatic tracking - skipping sync")
            return
        }
        
        print("🔄 Starting auto sync for \(autoTrackingHabits.count) habits...")
        print("📊 Habits to sync: \(autoTrackingHabits.map { $0.name })")
        
        var habitsUpdated = 0
        for habit in autoTrackingHabits {
            let wasUpdated = await syncHabit(habit)
            if wasUpdated {
                habitsUpdated += 1
            }
        }
        
        // Save all changes at once
        if habitsUpdated > 0 {
            do {
                try habitService.saveChanges()
                print("💾 Saved progress updates for \(habitsUpdated) habits")
            } catch {
                print("❌ Error saving habit progress: \(error)")
            }
        }
        
        lastSyncTime = Date()
        print("✅ Auto sync completed at \(DateFormatter.timeOnly.string(from: Date())) - \(habitsUpdated) habits updated")
    }
    
    private func syncHabit(_ habit: Habit) async -> Bool {
        let currentDate = dateManager.currentDate
        
        do {
            let progressValue: Double
            
            // Determine what data to fetch based on habit goals
            switch habit.goalUnit {
            case .steps:
                progressValue = try await healthKitService.getStepsForDate(currentDate)
                print("📊 \(habit.name): \(Int(progressValue)) steps (goal: \(Int(habit.goalTarget)))")
                
            case .minutes:
                // For exercise habits, fetch exercise minutes
                if habit.name.lowercased().contains("exercise") || habit.name.lowercased().contains("workout") {
                    progressValue = try await healthKitService.getExerciseMinutesForDate(currentDate)
                    print("📊 \(habit.name): \(Int(progressValue)) exercise minutes (goal: \(Int(habit.goalTarget)))")
                } else if habit.name.lowercased().contains("meditat") {
                    progressValue = try await healthKitService.getMindfulnessMinutesForDate(currentDate)
                    print("📊 \(habit.name): \(Int(progressValue)) mindfulness minutes (goal: \(Int(habit.goalTarget)))")
                } else {
                    // Default to exercise minutes for minute-based goals
                    progressValue = try await healthKitService.getExerciseMinutesForDate(currentDate)
                    print("📊 \(habit.name): \(Int(progressValue)) minutes (goal: \(Int(habit.goalTarget)))")
                }
                
                        default:
                print("⚠️ Unsupported goal unit for auto tracking: \(habit.goalUnit)")
                return false
            }
            
            // Update habit progress if the value has changed
            let previousProgress = habit.currentProgress
            
            // Reset progress if it's a new day
            if let lastCompletion = habit.lastCompletionDate,
               !Calendar.current.isDate(lastCompletion, inSameDayAs: currentDate) {
                habit.currentProgress = 0
            }
            
            // Always update progress for automatic habits to show real-time data
            let wasUpdated = abs(progressValue - previousProgress) >= 0.1 // Any change counts
            
            habit.currentProgress = progressValue
            
            // Check if goal was just completed
            if progressValue >= habit.goalTarget && !habit.isCompleted {
                habitService.completeHabit(habit)
                print("🎉 \(habit.name) goal completed automatically!")
            }
            
            print("🔄 Updated \(habit.name): \(Int(previousProgress)) → \(Int(habit.currentProgress))")
            
            return wasUpdated
            
        } catch {
            print("❌ Error syncing \(habit.name): \(error.localizedDescription)")
            syncError = error
            return false
        }
    }
    
    // MARK: - Manual Sync
    
    func manualSync() async {
        print("🔄 Manual sync requested")
        await syncAllHabits()
    }
    
    func forceSync() async {
        print("🔄 Force sync requested - immediate health data refresh")
        let previousLastSync = lastSyncTime
        lastSyncTime = nil // Reset to force fresh data and bypass time check
        await syncAllHabits()
        
        // If sync was successful, update lastSyncTime
        if lastSyncTime == nil {
            lastSyncTime = Date()
        }
    }
    
    // MARK: - Permissions Check
    
    func checkAndRequestPermissions() async {
        guard !healthKitService.isAuthorized else { return }
        
        do {
            try await healthKitService.requestPermissions()
            print("✅ HealthKit permissions granted - auto sync will start")
        } catch {
            print("❌ HealthKit permissions denied - automatic habits will show manual buttons")
            syncError = error
            // Don't force switch to manual - keep the tracking mode as chosen by user
        }
    }
    
    // MARK: - Permission Fallback
    
    private func handlePermissionsDenied() async {
        print("🔄 Switching auto-tracking habits to manual mode due to denied permissions")
        
        let autoTrackingHabits = habitService.habits.filter { $0.canUseAutoTracking }
        
        guard !autoTrackingHabits.isEmpty else { return }
        
        for habit in autoTrackingHabits {
            print("   📝 Switching \(habit.name) from automatic to manual tracking")
            habit.trackingMode = .manual
        }
        
        // Stop auto sync since no habits need it
        if habitService.habits.allSatisfy({ !$0.canUseAutoTracking }) {
            stopAutoSync()
            isAutoSyncEnabled = false
            print("⏹️ All habits switched to manual - auto sync disabled")
        }
        
        print("✅ Fallback to manual tracking completed for \(autoTrackingHabits.count) habits")
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()
} 