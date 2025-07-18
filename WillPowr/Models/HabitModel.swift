import Foundation
import CoreData

// MARK: - Habit Type Enums
enum HabitType: String, CaseIterable, Codable {
    case build = "build"
    case quit = "quit"
    
    var displayName: String {
        switch self {
        case .build:
            return "Build"
        case .quit:
            return "Quit"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .build:
            return "arrow.up.circle.fill"
        case .quit:
            return "xmark.circle.fill"
        }
    }
}

enum HabitCategory: String, CaseIterable, Codable {
    case health = "health"
    case fitness = "fitness"
    case mindfulness = "mindfulness"
    case productivity = "productivity"
    case social = "social"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .health:
            return "Health"
        case .fitness:
            return "Fitness"
        case .mindfulness:
            return "Mindfulness"
        case .productivity:
            return "Productivity"
        case .social:
            return "Social"
        case .custom:
            return "Custom"
        }
    }
}

// MARK: - Habit Model
struct HabitModel: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let type: HabitType
    let category: HabitCategory
    let systemImageName: String
    let createdAt: Date
    let streakCount: Int
    let lastCompletedDate: Date?
    let isActive: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        type: HabitType,
        category: HabitCategory,
        systemImageName: String,
        createdAt: Date = Date(),
        streakCount: Int = 0,
        lastCompletedDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.category = category
        self.systemImageName = systemImageName
        self.createdAt = createdAt
        self.streakCount = streakCount
        self.lastCompletedDate = lastCompletedDate
        self.isActive = isActive
    }
    
    // MARK: - Computed Properties
    var canCompleteToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return true }
        return !Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }
    
    var streakText: String {
        return "\(streakCount) day\(streakCount == 1 ? "" : "s")"
    }
    
    var completionButtonText: String {
        switch type {
        case .build:
            return canCompleteToday ? "Complete" : "Done Today"
        case .quit:
            return "I Failed"
        }
    }
    
    var completionButtonSystemImage: String {
        switch type {
        case .build:
            return canCompleteToday ? "checkmark.circle" : "checkmark.circle.fill"
        case .quit:
            return "xmark.circle"
        }
    }
}

// MARK: - Preset Habits
extension HabitModel {
    static let presetHabits: [HabitModel] = [
        // Build Habits
        HabitModel(
            name: "Walk Daily",
            type: .build,
            category: .fitness,
            systemImageName: "figure.walk"
        ),
        HabitModel(
            name: "Meditate",
            type: .build,
            category: .mindfulness,
            systemImageName: "leaf.fill"
        ),
        HabitModel(
            name: "Drink Water",
            type: .build,
            category: .health,
            systemImageName: "drop.fill"
        ),
        HabitModel(
            name: "Read Books",
            type: .build,
            category: .productivity,
            systemImageName: "book.fill"
        ),
        HabitModel(
            name: "Exercise",
            type: .build,
            category: .fitness,
            systemImageName: "dumbbell.fill"
        ),
        
        // Quit Habits
        HabitModel(
            name: "Quit Sugar",
            type: .quit,
            category: .health,
            systemImageName: "cube.fill"
        ),
        HabitModel(
            name: "Quit Social Media",
            type: .quit,
            category: .social,
            systemImageName: "iphone.slash"
        ),
        HabitModel(
            name: "Quit Smoking",
            type: .quit,
            category: .health,
            systemImageName: "smoke.fill"
        ),
        HabitModel(
            name: "Quit Junk Food",
            type: .quit,
            category: .health,
            systemImageName: "trash.fill"
        ),
        HabitModel(
            name: "Quit Procrastination",
            type: .quit,
            category: .productivity,
            systemImageName: "clock.fill"
        )
    ]
}

// MARK: - Core Data Entity
@objc(Habit)
public class Habit: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var typeRaw: String
    @NSManaged public var categoryRaw: String
    @NSManaged public var systemImageName: String
    @NSManaged public var createdAt: Date
    @NSManaged public var streakCount: Int32
    @NSManaged public var lastCompletedDate: Date?
    @NSManaged public var isActive: Bool
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.createdAt = Date()
        self.streakCount = 0
        self.isActive = true
    }
    
    var type: HabitType {
        get { HabitType(rawValue: typeRaw) ?? .build }
        set { typeRaw = newValue.rawValue }
    }
    
    var category: HabitCategory {
        get { HabitCategory(rawValue: categoryRaw) ?? .custom }
        set { categoryRaw = newValue.rawValue }
    }
    
    // Convert to HabitModel
    func toModel() -> HabitModel {
        HabitModel(
            id: id,
            name: name,
            type: type,
            category: category,
            systemImageName: systemImageName,
            createdAt: createdAt,
            streakCount: Int(streakCount),
            lastCompletedDate: lastCompletedDate,
            isActive: isActive
        )
    }
    
    // Update from HabitModel
    func updateFromModel(_ model: HabitModel) {
        self.id = model.id
        self.name = model.name
        self.type = model.type
        self.category = model.category
        self.systemImageName = model.systemImageName
        self.createdAt = model.createdAt
        self.streakCount = Int32(model.streakCount)
        self.lastCompletedDate = model.lastCompletedDate
        self.isActive = model.isActive
    }
}

// MARK: - Core Data Fetch Request
extension Habit {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
        return NSFetchRequest<Habit>(entityName: "Habit")
    }
    
    static func activeHabits() -> NSFetchRequest<Habit> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Habit.createdAt, ascending: false)]
        return request
    }
} 