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
            fatalError("Could not create ModelContainer: \(error)")
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
