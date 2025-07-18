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
        ])
        
        do {
            // Create a simple, persistent ModelContainer
            let container = try ModelContainer(for: schema)
            print("✅ Successfully created persistent ModelContainer")
            
            // Get the actual storage location
            if let storeURL = container.configurations.first?.url {
                print("📂 Persistent storage at: \(storeURL.path)")
                print("📂 Storage exists: \(FileManager.default.fileExists(atPath: storeURL.path))")
            } else {
                print("⚠️ No storage URL found")
            }
            
            return container
        } catch {
            print("❌ ModelContainer creation failed: \(error)")
            
            // Handle migration errors by deleting the old store
            if error.localizedDescription.contains("migration") || error.localizedDescription.contains("134110") {
                print("🔧 Attempting to fix migration issue by clearing old data...")
                
                // Try to delete the old store and create a fresh one
                do {
                    let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                    let storeURL = appSupportURL.appendingPathComponent("default.store")
                    
                    if FileManager.default.fileExists(atPath: storeURL.path) {
                        try FileManager.default.removeItem(at: storeURL)
                        print("🗑️ Deleted old database file")
                    }
                    
                    // Create fresh container
                    let freshContainer = try ModelContainer(for: schema)
                    print("✅ Created fresh ModelContainer after clearing old data")
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
}

struct AppRootView: View {
    let modelContainer: ModelContainer
    @State private var habitService: HabitService?
    @StateObject private var dateManager = DateManager()
    @StateObject private var healthKitService = HealthKitService()
    @AppStorage("hasShownPermissions") private var hasShownPermissions = false
    @State private var showPermissions = false
    
    var body: some View {
        Group {
            if let habitService = habitService {
                ContentView()
                    .environmentObject(habitService)
                    .environmentObject(dateManager)
                    .environmentObject(healthKitService)
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
            // Create HabitService on MainActor
            let service = HabitService(modelContext: modelContainer.mainContext, dateManager: dateManager)
            habitService = service
            
            // Check HealthKit authorization status
            healthKitService.checkAuthorizationStatus()
            
            // Show permissions popup on first launch
            if !hasShownPermissions {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPermissions = true
                }
            }
        }
    }
}
