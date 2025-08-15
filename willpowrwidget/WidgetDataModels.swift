//
//  WidgetDataModels.swift
//  willpowrwidget
//
//  Data models for widget display
//

import Foundation
import SwiftUI
import SwiftData
import WidgetKit

// MARK: - Widget Entry

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let habitData: HabitWidgetData?
    let configuration: HabitSelectionIntent
}

// MARK: - Habit Widget Data

struct HabitWidgetData {
    let id: String
    let name: String
    let iconName: String
    let habitType: HabitType
    let streak: Int
    let longestStreak: Int
    let isCompleted: Bool
    let lastCompletionDate: Date?
    let goalTarget: Double
    let goalUnit: GoalUnit
    let currentProgress: Double
    let activityData: [DayActivity]
    let daysToShow: Int
    
    var isCompletedToday: Bool {
        guard let lastCompletion = lastCompletionDate else { return false }
        return Calendar.current.isDateInToday(lastCompletion)
    }
    
    var progressPercentage: Double {
        guard goalTarget > 0 else { return 0 }
        return min(currentProgress / goalTarget, 1.0)
    }
    
    var displayProgress: String {
        if goalUnit == .none {
            return isCompleted ? "Complete" : "Incomplete"
        }
        let current = formatValue(currentProgress)
        let target = formatValue(goalTarget)
        return "\(current)/\(target) \(goalUnit.displayName)"
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Day Activity

struct DayActivity {
    let date: Date
    let isCompleted: Bool
    let progressPercentage: Double
    
    var activityLevel: ActivityLevel {
        if !isCompleted && progressPercentage == 0 {
            return .none
        } else if progressPercentage < 0.25 {
            return .low
        } else if progressPercentage < 0.5 {
            return .medium
        } else if progressPercentage < 0.75 {
            return .high
        } else {
            return .complete
        }
    }
}

enum ActivityLevel: Hashable {
    case none
    case low
    case medium
    case high
    case complete
    
    func color(for habitType: HabitType) -> Color {
        switch self {
        case .none:
            return Color.white.opacity(0.05)
        case .low:
            return habitType == .build ? 
                Color.blue.opacity(0.25) : Color.red.opacity(0.25)
        case .medium:
            return habitType == .build ? 
                Color.blue.opacity(0.45) : Color.orange.opacity(0.45)
        case .high:
            return habitType == .build ? 
                Color.blue.opacity(0.65) : Color.yellow.opacity(0.65)
        case .complete:
            return habitType == .build ? 
                Color.blue.opacity(0.85) : Color.green.opacity(0.85)
        }
    }
}

// MARK: - Widget Data Provider

class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private init() {}
    
    func fetchHabitData(for habitId: String?) -> HabitWidgetData? {
        guard let habitId = habitId else { return nil }
        
        // Use a synchronous approach for widget data
        let semaphore = DispatchSemaphore(value: 0)
        var result: HabitWidgetData?
        
        Task { @MainActor in
            defer { semaphore.signal() }
            
            // Set up SwiftData container with app group
            guard let container = try? ModelContainer(
                for: Habit.self, HabitEntry.self,
                configurations: ModelConfiguration(
                    url: FileManager.default
                        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.gill.WillPowr")!
                        .appendingPathComponent("WillPowr.sqlite")
                )
            ) else {
                print("Widget: Failed to create model container")
                return
            }
            
            let context = ModelContext(container)
            
            // Fetch the specific habit
            guard let habitUUID = UUID(uuidString: habitId),
                  let habit = try? context.fetch(
                    FetchDescriptor<Habit>(
                        predicate: #Predicate { $0.id == habitUUID }
                    )
                  ).first else {
                print("Widget: Habit not found for ID: \(habitId)")
                return
            }
            
            // Generate activity data for the last N days
            let activityData = generateActivityData(for: habit, days: 90)
            
            result = HabitWidgetData(
                id: habit.id.uuidString,
                name: habit.name,
                iconName: habit.iconName,
                habitType: habit.habitType,
                streak: habit.streak,
                longestStreak: habit.longestStreak,
                isCompleted: habit.isCompleted,
                lastCompletionDate: habit.lastCompletionDate,
                goalTarget: habit.goalTarget,
                goalUnit: habit.goalUnit,
                currentProgress: habit.currentProgress,
                activityData: activityData,
                daysToShow: 90
            )
        }
        
        semaphore.wait()
        return result
    }
    
    private func generateActivityData(for habit: Habit, days: Int) -> [DayActivity] {
        let calendar = Calendar.current
        let today = Date()
        var activities: [DayActivity] = []
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            
            // Find entry for this date
            let dayStart = calendar.startOfDay(for: date)
            let entry = habit.entries.first { entry in
                calendar.isDate(entry.date, inSameDayAs: dayStart)
            }
            
            let activity = DayActivity(
                date: date,
                isCompleted: entry?.isCompleted ?? false,
                progressPercentage: entry?.progressPercentage ?? 0
            )
            
            activities.append(activity)
        }
        
        return activities.reversed() // Return in chronological order
    }
    
    func fetchAllHabits() -> [HabitWidgetData] {
        let semaphore = DispatchSemaphore(value: 0)
        var result: [HabitWidgetData] = []
        
        Task { @MainActor in
            defer { semaphore.signal() }
            
            guard let container = try? ModelContainer(
                for: Habit.self, HabitEntry.self,
                configurations: ModelConfiguration(
                    url: FileManager.default
                        .containerURL(forSecurityApplicationGroupIdentifier: "group.com.gill.WillPowr")!
                        .appendingPathComponent("WillPowr.sqlite")
                )
            ) else {
                return
            }
            
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<Habit>(
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            
            do {
                let habits = try context.fetch(descriptor)
                result = habits.compactMap { habit in
                    let activityData = generateActivityData(for: habit, days: 90)
                    return HabitWidgetData(
                        id: habit.id.uuidString,
                        name: habit.name,
                        iconName: habit.iconName,
                        habitType: habit.habitType,
                        streak: habit.streak,
                        longestStreak: habit.longestStreak,
                        isCompleted: habit.isCompleted,
                        lastCompletionDate: habit.lastCompletionDate,
                        goalTarget: habit.goalTarget,
                        goalUnit: habit.goalUnit,
                        currentProgress: habit.currentProgress,
                        activityData: activityData,
                        daysToShow: 90
                    )
                }
            } catch {
                print("Widget: Failed to fetch all habits: \(error)")
            }
        }
        
        semaphore.wait()
        return result
    }
}