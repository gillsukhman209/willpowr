//
//  HabitSelectionIntent.swift
//  willpowrwidget
//
//  Widget configuration for habit selection
//

import WidgetKit
import AppIntents
import SwiftData

// MARK: - Habit Entity for AppIntents

struct HabitEntity: AppEntity {
    let id: String
    let name: String
    let iconName: String
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static var defaultQuery = HabitEntityQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

// MARK: - Habit Query

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        let habits = await fetchAllHabits()
        return habits.filter { identifiers.contains($0.id) }
    }
    
    func suggestedEntities() async throws -> [HabitEntity] {
        return await fetchAllHabits()
    }
    
    func defaultResult() async -> HabitEntity? {
        return await fetchAllHabits().first
    }
    
    private func fetchAllHabits() async -> [HabitEntity] {
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                // Access SwiftData from app group container
                guard let container = try? ModelContainer(
                    for: Habit.self, HabitEntry.self,
                    configurations: ModelConfiguration(
                        url: FileManager.default
                            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.gill.WillPowr")!
                            .appendingPathComponent("WillPowr.sqlite")
                    )
                ) else {
                    continuation.resume(returning: [])
                    return
                }
                
                let context = ModelContext(container)
                let descriptor = FetchDescriptor<Habit>(
                    sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
                )
                
                do {
                    let habits = try context.fetch(descriptor)
                    let habitEntities = habits.map { habit in
                        HabitEntity(
                            id: habit.id.uuidString,
                            name: habit.name,
                            iconName: habit.iconName
                        )
                    }
                    continuation.resume(returning: habitEntities)
                } catch {
                    print("Widget: Failed to fetch habits: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

// MARK: - Widget Configuration Intent

struct HabitSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Habit"
    static var description = IntentDescription("Choose which habit to display in the widget")
    
    @Parameter(title: "Habit")
    var habit: HabitEntity?
    
    @Parameter(title: "Days to Show", default: 90)
    var daysToShow: Int
    
    init() {
        self.daysToShow = 90
    }
    
    init(habit: HabitEntity?, daysToShow: Int = 90) {
        self.habit = habit
        self.daysToShow = daysToShow
    }
}