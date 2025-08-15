//
//  WillPowrApp.swift
//  WillPowr
//
//  Created by Sukhman Singh on 7/18/25.
//

import SwiftUI
import SwiftData

@main
struct WillPowrApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            HabitEntry.self,
        ])
        
        do {
            // Get the app group container URL
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.gill.WillPowr"
            ) else {
                fatalError("Failed to get app group container URL. Check your app group configuration.")
            }
            
            // Create the shared database URL
            let storeURL = containerURL.appendingPathComponent("WillPowr.sqlite")
            
            // Create ModelContainer with shared configuration
            let config = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
            
            let container = try ModelContainer(for: schema, configurations: config)
            print("✅ Successfully created shared ModelContainer")
            print("📂 Shared storage at: \(storeURL.path)")
            print("📂 Storage exists: \(FileManager.default.fileExists(atPath: storeURL.path))")
            
            return container
        } catch {
            print("❌ ModelContainer creation failed: \(error)")
            
            // Handle migration errors by deleting the old store
            if error.localizedDescription.contains("migration") || error.localizedDescription.contains("134110") || error.localizedDescription.contains("cast") || error.localizedDescription.contains("TrackingMode") {
                print("🔧 Schema change detected - clearing old data to prevent migration issues...")
                
                // Try to delete the old store and create a fresh one
                do {
                    guard let containerURL = FileManager.default.containerURL(
                        forSecurityApplicationGroupIdentifier: "group.com.gill.WillPowr"
                    ) else {
                        fatalError("Failed to get app group container URL")
                    }
                    
                    let storeURL = containerURL.appendingPathComponent("WillPowr.sqlite")
                    
                    if FileManager.default.fileExists(atPath: storeURL.path) {
                        try FileManager.default.removeItem(at: storeURL)
                        print("🗑️ Deleted old database file for schema migration")
                    }
                    
                    // Also try to clean up any related files
                    let storeWalURL = containerURL.appendingPathComponent("WillPowr.sqlite-wal")
                    let storeShmURL = containerURL.appendingPathComponent("WillPowr.sqlite-shm")
                    
                    if FileManager.default.fileExists(atPath: storeWalURL.path) {
                        try? FileManager.default.removeItem(at: storeWalURL)
                    }
                    
                    if FileManager.default.fileExists(atPath: storeShmURL.path) {
                        try? FileManager.default.removeItem(at: storeShmURL)
                    }
                    
                    // Create fresh container with shared configuration
                    let config = ModelConfiguration(
                        schema: schema,
                        url: storeURL,
                        allowsSave: true
                    )
                    let freshContainer = try ModelContainer(for: schema, configurations: config)
                    print("✅ Created fresh shared ModelContainer after schema migration")
                    return freshContainer
                    
                } catch {
                    print("❌ Failed to create fresh container: \(error)")
                    fatalError("Cannot run app without persistent storage: \(error)")
                }
            } else {
                fatalError("Cannot run app without persistent storage: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            AppRootView(modelContainer: sharedModelContainer)
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.dark)
        }
    }
    
    struct AppRootView: View {
        let modelContainer: ModelContainer
        @State private var habitService: HabitService?
        @State private var autoSyncService: AutoSyncService?
        @State private var backgroundSyncService: BackgroundSyncService?
        @StateObject private var dateManager = DateManager()
        @StateObject private var healthKitService = HealthKitService()
        @StateObject private var notificationService = NotificationService()
        @AppStorage("hasShownPermissions") private var hasShownPermissions = false
        @State private var showPermissions = false
        
        var body: some View {
            Group {
                if let habitService = habitService, 
                   let autoSyncService = autoSyncService,
                   let backgroundSyncService = backgroundSyncService {
                    ContentView()
                        .environmentObject(habitService)
                        .environmentObject(dateManager)
                        .environmentObject(healthKitService)
                        .environmentObject(notificationService)
                        .environmentObject(autoSyncService)
                        .environmentObject(backgroundSyncService)
                        .sheet(isPresented: $showPermissions) {
                            PermissionsView()
                                .environmentObject(healthKitService)
                        }
                } else {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                }
            }
            .task {
                // Set DateManager for HealthKitService
                healthKitService.setDateManager(dateManager)
                
                // Create HabitService on MainActor
                let service = HabitService(modelContext: modelContainer.mainContext, dateManager: dateManager)
                habitService = service
                
                // Connect services for notification updates
                service.setNotificationService(notificationService)
                
                // Validate and repair all streaks on startup (NEW SYSTEM)
                service.validateAndRepairAllStreaks()
                
                // Request notification permission and setup reminders on app launch
                Task {
                    let granted = await notificationService.requestPermission()
                    if granted {
                        // Schedule smart reminders once permission is granted
                        notificationService.scheduleHabitReminders(for: service)
                    }
                }
                
                // Create AutoSyncService after HabitService is available
                let syncService = AutoSyncService(
                    habitService: service,
                    healthKitService: healthKitService,
                    dateManager: dateManager
                )
                autoSyncService = syncService
                
                // Create BackgroundSyncService
                let backgroundService = BackgroundSyncService(
                    habitService: service,
                    healthKitService: healthKitService,
                    dateManager: dateManager
                )
                backgroundSyncService = backgroundService
                
                // Initialize background service
                await backgroundService.initialize()
                
                // Check HealthKit authorization status with read access test
                healthKitService.checkAuthorizationStatus()
                
                // Trigger initial sync after services are set up
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    Task {
                        print("🚀 App launched - triggering initial health data sync")
                        await syncService.syncAllHabits()
                    }
                }
                
                // Show permissions popup on first launch
                if !hasShownPermissions {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showPermissions = true
                    }
                }
            }
        }
    }
}
