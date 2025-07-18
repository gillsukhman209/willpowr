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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ Failed to create ModelContainer: \(error)")
            
            // Try to create a fresh container by clearing the store
            do {
                let freshConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                let freshContainer = try ModelContainer(for: schema, configurations: [freshConfiguration])
                print("✅ Created fresh ModelContainer after clearing store")
                return freshContainer
            } catch {
                print("❌ Failed to create fresh ModelContainer: \(error)")
                // As a last resort, use in-memory storage
                do {
                    let inMemoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    let inMemoryContainer = try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
                    print("⚠️ Using in-memory storage as fallback")
                    return inMemoryContainer
                } catch {
                    fatalError("Could not create any ModelContainer: \(error)")
                }
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
    
    var body: some View {
        Group {
            if let habitService = habitService {
                ContentView()
                    .environment(\.habitService, habitService)
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
            let service = HabitService(modelContext: modelContainer.mainContext)
            habitService = service
        }
    }
}
