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
    
    @Parameter(title: "Days to Show", default: DaysOption.ninety)
    var daysToShow: DaysOption
    
    init() {
        self.daysToShow = .ninety
    }
    
    init(habit: HabitEntity?, daysToShow: DaysOption = .ninety) {
        self.habit = habit
        self.daysToShow = daysToShow
    }
}

// MARK: - Days Option

enum DaysOption: String, CaseIterable, AppEnum {
    case seven = "7"
    case thirty = "30"
    case sixty = "60"
    case ninety = "90"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Days to Show"
    static var caseDisplayRepresentations: [DaysOption: DisplayRepresentation] = [
        .seven: "Last 7 days",
        .thirty: "Last 30 days", 
        .sixty: "Last 60 days",
        .ninety: "Last 90 days"
    ]
    
    var intValue: Int {
        switch self {
        case .seven: return 7
        case .thirty: return 30
        case .sixty: return 60
        case .ninety: return 90
        }
    }
}