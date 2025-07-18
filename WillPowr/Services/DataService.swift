import Foundation
import CoreData
import Combine

// MARK: - Data Service Protocol
protocol DataServiceProtocol {
    func saveHabit(_ habit: HabitModel) async throws
    func loadHabits() async throws -> [HabitModel]
    func updateHabit(_ habit: HabitModel) async throws
    func deleteHabit(_ habit: HabitModel) async throws
    func completeHabit(_ habit: HabitModel) async throws -> HabitModel
    func resetHabitStreak(_ habit: HabitModel) async throws -> HabitModel
}

// MARK: - Core Data Service
@MainActor
class DataService: ObservableObject, DataServiceProtocol {
    static let shared = DataService()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WillPowr")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Published Properties
    @Published var habits: [HabitModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {
        Task {
            await loadHabitsFromStore()
        }
    }
    
    // MARK: - Core Data Operations
    func saveContext() async throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Habit Operations
    func saveHabit(_ habit: HabitModel) async throws {
        let habitEntity = Habit(context: context)
        habitEntity.updateFromModel(habit)
        
        try await saveContext()
        await loadHabitsFromStore()
    }
    
    func loadHabits() async throws -> [HabitModel] {
        let request = Habit.activeHabits()
        let habitEntities = try context.fetch(request)
        return habitEntities.map { $0.toModel() }
    }
    
    func updateHabit(_ habit: HabitModel) async throws {
        let request = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
        
        let results = try context.fetch(request)
        guard let habitEntity = results.first else {
            throw DataError.habitNotFound
        }
        
        habitEntity.updateFromModel(habit)
        try await saveContext()
        await loadHabitsFromStore()
    }
    
    func deleteHabit(_ habit: HabitModel) async throws {
        let request = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", habit.id as CVarArg)
        
        let results = try context.fetch(request)
        guard let habitEntity = results.first else {
            throw DataError.habitNotFound
        }
        
        context.delete(habitEntity)
        try await saveContext()
        await loadHabitsFromStore()
    }
    
    func completeHabit(_ habit: HabitModel) async throws -> HabitModel {
        guard habit.canCompleteToday else {
            throw DataError.habitAlreadyCompleted
        }
        
        let today = Date()
        let newStreakCount: Int
        
        switch habit.type {
        case .build:
            // For build habits, increment streak
            if let lastCompleted = habit.lastCompletedDate,
               Calendar.current.isDate(lastCompleted, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today) {
                // Consecutive day - increment streak
                newStreakCount = habit.streakCount + 1
            } else if habit.lastCompletedDate == nil {
                // First time completing
                newStreakCount = 1
            } else {
                // Broke streak - reset to 1
                newStreakCount = 1
            }
        case .quit:
            // For quit habits, this shouldn't be called - use resetHabitStreak instead
            throw DataError.invalidOperation
        }
        
        let updatedHabit = HabitModel(
            id: habit.id,
            name: habit.name,
            type: habit.type,
            category: habit.category,
            systemImageName: habit.systemImageName,
            createdAt: habit.createdAt,
            streakCount: newStreakCount,
            lastCompletedDate: today,
            isActive: habit.isActive
        )
        
        try await updateHabit(updatedHabit)
        return updatedHabit
    }
    
    func resetHabitStreak(_ habit: HabitModel) async throws -> HabitModel {
        let updatedHabit = HabitModel(
            id: habit.id,
            name: habit.name,
            type: habit.type,
            category: habit.category,
            systemImageName: habit.systemImageName,
            createdAt: habit.createdAt,
            streakCount: 0,
            lastCompletedDate: Date(),
            isActive: habit.isActive
        )
        
        try await updateHabit(updatedHabit)
        return updatedHabit
    }
    
    // MARK: - Private Methods
    private func loadHabitsFromStore() async {
        isLoading = true
        error = nil
        
        do {
            let loadedHabits = try await loadHabits()
            habits = loadedHabits
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

// MARK: - Data Errors
enum DataError: LocalizedError {
    case habitNotFound
    case habitAlreadyCompleted
    case invalidOperation
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .habitNotFound:
            return "Habit not found"
        case .habitAlreadyCompleted:
            return "Habit already completed today"
        case .invalidOperation:
            return "Invalid operation for this habit type"
        case .saveFailed:
            return "Failed to save habit"
        }
    }
}

// MARK: - Preview Mock
#if DEBUG
class MockDataService: DataServiceProtocol {
    var habits: [HabitModel] = []
    
    func saveHabit(_ habit: HabitModel) async throws {
        habits.append(habit)
    }
    
    func loadHabits() async throws -> [HabitModel] {
        return habits
    }
    
    func updateHabit(_ habit: HabitModel) async throws {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        }
    }
    
    func deleteHabit(_ habit: HabitModel) async throws {
        habits.removeAll { $0.id == habit.id }
    }
    
    func completeHabit(_ habit: HabitModel) async throws -> HabitModel {
        let updatedHabit = HabitModel(
            id: habit.id,
            name: habit.name,
            type: habit.type,
            category: habit.category,
            systemImageName: habit.systemImageName,
            createdAt: habit.createdAt,
            streakCount: habit.streakCount + 1,
            lastCompletedDate: Date(),
            isActive: habit.isActive
        )
        try await updateHabit(updatedHabit)
        return updatedHabit
    }
    
    func resetHabitStreak(_ habit: HabitModel) async throws -> HabitModel {
        let updatedHabit = HabitModel(
            id: habit.id,
            name: habit.name,
            type: habit.type,
            category: habit.category,
            systemImageName: habit.systemImageName,
            createdAt: habit.createdAt,
            streakCount: 0,
            lastCompletedDate: Date(),
            isActive: habit.isActive
        )
        try await updateHabit(updatedHabit)
        return updatedHabit
    }
}
#endif 