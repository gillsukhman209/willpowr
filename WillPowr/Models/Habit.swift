import Foundation
import SwiftData

// MARK: - Goal Units

enum GoalUnit: String, CaseIterable, Codable {
    case steps = "steps"
    case minutes = "minutes"
    case hours = "hours"
    case liters = "liters"
    case glasses = "glasses"
    case grams = "grams"
    case count = "count"
    case none = "none" // for binary habits (complete/incomplete)
    
    var displayName: String {
        switch self {
        case .steps: return "steps"
        case .minutes: return "min"
        case .hours: return "hrs"
        case .liters: return "L"
        case .glasses: return "glasses"
        case .grams: return "g"
        case .count: return "times"
        case .none: return ""
        }
    }
    
    var longDisplayName: String {
        switch self {
        case .steps: return "steps"
        case .minutes: return "minutes"
        case .hours: return "hours"
        case .liters: return "liters"
        case .glasses: return "glasses"
        case .grams: return "grams"
        case .count: return "times"
        case .none: return ""
        }
    }
    
    var supportsAutoTracking: Bool {
        switch self {
        case .steps, .minutes: return true // HealthKit can track steps and exercise minutes
        case .hours, .liters, .glasses, .grams, .count, .none: return false
        }
    }
}

// MARK: - Tracking Mode

enum TrackingMode: String, CaseIterable, Codable {
    case automatic = "automatic"
    case manual = "manual"
    
    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .manual: return "Manual"
        }
    }
    
    var description: String {
        switch self {
        case .automatic: return "Track progress automatically using HealthKit data"
        case .manual: return "Manually log progress with buttons"
        }
    }
    
    var iconName: String {
        switch self {
        case .automatic: return "waveform.path.ecg"
        case .manual: return "hand.tap.fill"
        }
    }
}

// MARK: - Quit Habit Type

enum QuitHabitType: String, CaseIterable, Codable {
    case abstinence = "abstinence"
    case limit = "limit"
    
    var displayName: String {
        switch self {
        case .abstinence: return "Complete Abstinence"
        case .limit: return "Daily Limit"
        }
    }
    
    var description: String {
        switch self {
        case .abstinence: return "Completely avoid this behavior"
        case .limit: return "Set a daily limit for this behavior"
        }
    }
    
    var iconName: String {
        switch self {
        case .abstinence: return "xmark.circle.fill"
        case .limit: return "gauge.with.dots.needle.33percent"
        }
    }
}

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitType: HabitType
    var iconName: String
    var streak: Int
    var longestStreak: Int = 0 // Track the best-ever streak
    var isCompleted: Bool
    var lastCompletionDate: Date?
    var createdDate: Date
    var isCustom: Bool
    
    // MARK: - Goal Properties
    var goalTarget: Double = 1.0 // Default value for migration
    var goalUnit: GoalUnit = GoalUnit.none // Default value for migration
    var currentProgress: Double = 0.0 // Default value for migration
    var goalDescription: String? // Optional for migration
    var trackingMode: TrackingMode = TrackingMode.manual // Default value for migration
    var quitHabitType: QuitHabitType = QuitHabitType.abstinence // Default for migration
    
    // MARK: - History Relationship
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []
    
    init(name: String, habitType: HabitType, iconName: String, isCustom: Bool = false, goalTarget: Double = 1, goalUnit: GoalUnit = .none, goalDescription: String? = nil, trackingMode: TrackingMode = .manual, quitHabitType: QuitHabitType = .abstinence) {
        self.id = UUID()
        self.name = name
        self.habitType = habitType
        self.iconName = iconName
        self.streak = 0
        self.longestStreak = 0
        self.isCompleted = false
        self.lastCompletionDate = nil
        self.createdDate = Date()
        self.isCustom = isCustom
        self.goalTarget = goalTarget
        self.goalUnit = goalUnit
        self.currentProgress = 0
        self.goalDescription = goalDescription
        self.trackingMode = trackingMode
        self.quitHabitType = quitHabitType
    }
    
    // MARK: - Computed Properties
    
    var isGoalMet: Bool {
        if goalUnit == .none {
            return isCompleted
        }
        return currentProgress >= goalTarget
    }
    
    var progressPercentage: Double {
        guard goalTarget > 0 else { return 0 }
        return min(currentProgress / goalTarget, 1.0)
    }
    
    var displayProgress: String {
        if goalUnit == .none {
            return isCompleted ? "Complete" : "Not Complete"
        }
        
        let current = formatValue(currentProgress)
        let target = formatValue(goalTarget)
        
        return "\(current) / \(target) \(goalUnit.displayName)"
    }
    
    var canUseAutoTracking: Bool {
        return goalUnit.supportsAutoTracking && trackingMode == .automatic
    }
    
    var shouldShowTrackingModeOption: Bool {
        return goalUnit.supportsAutoTracking
    }
    
    func canComplete(on date: Date) -> Bool {
        guard let lastDate = lastCompletionDate else { return true }
        return !Calendar.current.isDate(lastDate, inSameDayAs: date)
    }
    
    var canCompleteToday: Bool {
        return canComplete(on: Date())
    }
    
    // MARK: - Quit Habit Properties
    
    var isQuitHabit: Bool {
        return habitType == .quit
    }
    
    var isAbstinenceHabit: Bool {
        return habitType == .quit && quitHabitType == .abstinence
    }
    
    var isLimitHabit: Bool {
        return habitType == .quit && quitHabitType == .limit
    }
    
    var isSuccessfulToday: Bool {
        if habitType == .build {
            return isGoalMet
        } else if isAbstinenceHabit {
            // For abstinence habits, success = explicitly marked as completed today AND no progress
            let today = Date()
            let isCompletedToday = if let lastCompletion = lastCompletionDate {
                Calendar.current.isDate(lastCompletion, inSameDayAs: today)
            } else {
                false
            }
            return isCompletedToday && currentProgress == 0
        } else if isLimitHabit {
            // For limit habits, success = under or at the limit
            return currentProgress <= goalTarget
        }
        return isGoalMet
    }
    
    var quitHabitStatusText: String {
        if isAbstinenceHabit {
            if isSuccessfulToday {
                return "Stayed Clean Today"
            } else if currentProgress > 0 {
                return "Relapsed Today"
            } else {
                return "No Activity Yet Today"
            }
        } else if isLimitHabit {
            let current = formatValue(currentProgress)
            let limit = formatValue(goalTarget)
            let status = currentProgress <= goalTarget ? "✅" : "⚠️"
            return "\(status) \(current) / \(limit) \(goalUnit.displayName)"
        }
        return displayProgress
    }
    
    var cleanDaysStreak: Int {
        // For quit habits, streak represents consecutive clean/successful days
        return isSuccessfulToday ? streak : 0
    }
    
    var hasInteractedToday: Bool {
        let today = Date()
        if let lastCompletion = lastCompletionDate,
           Calendar.current.isDate(lastCompletion, inSameDayAs: today) {
            return true
        }
        // For abstinence habits, having progress > 0 means they failed today
        if isAbstinenceHabit && currentProgress > 0 {
            return true
        }
        return false
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    // MARK: - History Methods
    
    var sortedEntries: [HabitEntry] {
        return entries.sorted { $0.date > $1.date }
    }
    
    var recentEntries: [HabitEntry] {
        return Array(sortedEntries.prefix(30)) // Last 30 days
    }
    
    func entryFor(date: Date) -> HabitEntry? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return entries.first { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }
    }
    
    func entriesInRange(from startDate: Date, to endDate: Date) -> [HabitEntry] {
        return entries.filter { entry in
            entry.date >= Calendar.current.startOfDay(for: startDate) &&
            entry.date <= Calendar.current.startOfDay(for: endDate)
        }.sorted { $0.date < $1.date }
    }
    
    var weeklyAverage: Double {
        let lastWeekEntries = entriesInRange(
            from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            to: Date()
        )
        
        guard !lastWeekEntries.isEmpty else { return 0 }
        
        let totalProgress = lastWeekEntries.reduce(0) { $0 + $1.progress }
        return totalProgress / Double(lastWeekEntries.count)
    }
    
    var monthlyAverage: Double {
        let lastMonthEntries = entriesInRange(
            from: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            to: Date()
        )
        
        guard !lastMonthEntries.isEmpty else { return 0 }
        
        let totalProgress = lastMonthEntries.reduce(0) { $0 + $1.progress }
        return totalProgress / Double(lastMonthEntries.count)
    }
}

// MARK: - Habit Type Enum

enum HabitType: String, CaseIterable, Codable {
    case build = "build"
    case quit = "quit"
    
    var displayName: String {
        switch self {
        case .build: return "Build"
        case .quit: return "Quit"
        }
    }
    
    var color: String {
        switch self {
        case .build: return "green"
        case .quit: return "red"
        }
    }
}

// MARK: - Preset Habits

struct PresetHabit {
    let name: String
    let iconName: String
    let habitType: HabitType
    let defaultGoalTarget: Double
    let defaultGoalUnit: GoalUnit
    let goalDescription: String?
    let defaultTrackingMode: TrackingMode
    let defaultQuitHabitType: QuitHabitType
    
    init(name: String, iconName: String, habitType: HabitType, defaultGoalTarget: Double = 1, defaultGoalUnit: GoalUnit = .none, goalDescription: String? = nil, defaultTrackingMode: TrackingMode = .manual, defaultQuitHabitType: QuitHabitType = .abstinence) {
        self.name = name
        self.iconName = iconName
        self.habitType = habitType
        self.defaultGoalTarget = defaultGoalTarget
        self.defaultGoalUnit = defaultGoalUnit
        self.goalDescription = goalDescription
        self.defaultTrackingMode = defaultTrackingMode
        self.defaultQuitHabitType = defaultQuitHabitType
    }
}

extension PresetHabit {
    static let buildHabits: [PresetHabit] = [
        PresetHabit(name: "Walk Daily", iconName: "figure.walk", habitType: .build, defaultGoalTarget: 8000, defaultGoalUnit: .steps, goalDescription: "Walk 8,000 steps daily", defaultTrackingMode: .automatic),
        PresetHabit(name: "Meditate", iconName: "brain.head.profile", habitType: .build, defaultGoalTarget: 10, defaultGoalUnit: .minutes, goalDescription: "Meditate for 10 minutes daily", defaultTrackingMode: .automatic),
        PresetHabit(name: "Drink Water", iconName: "drop.fill", habitType: .build, defaultGoalTarget: 2, defaultGoalUnit: .liters, goalDescription: "Drink 2 liters of water daily", defaultTrackingMode: .manual),
        PresetHabit(name: "Read", iconName: "book.fill", habitType: .build, defaultGoalTarget: 20, defaultGoalUnit: .minutes, goalDescription: "Read for 20 minutes daily", defaultTrackingMode: .manual),
        PresetHabit(name: "Exercise", iconName: "dumbbell.fill", habitType: .build, defaultGoalTarget: 30, defaultGoalUnit: .minutes, goalDescription: "Exercise for 30 minutes daily", defaultTrackingMode: .automatic),
        PresetHabit(name: "Journal", iconName: "pencil.and.outline", habitType: .build, defaultGoalTarget: 1, defaultGoalUnit: .none, goalDescription: "Write in journal daily", defaultTrackingMode: .manual),
        PresetHabit(name: "Sleep Early", iconName: "bed.double.fill", habitType: .build, defaultGoalTarget: 1, defaultGoalUnit: .none, goalDescription: "Sleep before 11 PM daily", defaultTrackingMode: .manual)
    ]
    
    static let quitHabits: [PresetHabit] = [
        // Abstinence-based quit habits (complete avoidance)
        PresetHabit(name: "Quit Smoking", iconName: "smoke.fill", habitType: .quit, defaultGoalTarget: 0, defaultGoalUnit: .none, goalDescription: "Completely avoid smoking", defaultQuitHabitType: .abstinence),
        PresetHabit(name: "Quit Vaping", iconName: "cloud.fill", habitType: .quit, defaultGoalTarget: 0, defaultGoalUnit: .none, goalDescription: "Completely avoid vaping", defaultQuitHabitType: .abstinence),
        PresetHabit(name: "Quit Drinking", iconName: "wineglass.fill", habitType: .quit, defaultGoalTarget: 0, defaultGoalUnit: .none, goalDescription: "Completely avoid alcohol", defaultQuitHabitType: .abstinence),
        PresetHabit(name: "Avoid Gambling", iconName: "dice.fill", habitType: .quit, defaultGoalTarget: 0, defaultGoalUnit: .none, goalDescription: "Completely avoid gambling", defaultQuitHabitType: .abstinence),
        PresetHabit(name: "Stop Nail Biting", iconName: "hand.raised.fill", habitType: .quit, defaultGoalTarget: 0, defaultGoalUnit: .none, goalDescription: "Completely avoid nail biting", defaultQuitHabitType: .abstinence),
        
        // Limit-based quit habits (daily limits)
        PresetHabit(name: "Limit Social Media", iconName: "iphone.slash", habitType: .quit, defaultGoalTarget: 1, defaultGoalUnit: .hours, goalDescription: "Limit social media to 1 hour daily", defaultQuitHabitType: .limit),
        PresetHabit(name: "Limit Screen Time", iconName: "tv.fill", habitType: .quit, defaultGoalTarget: 6, defaultGoalUnit: .hours, goalDescription: "Limit screen time to 6 hours daily", defaultQuitHabitType: .limit),
        PresetHabit(name: "Limit Coffee", iconName: "cup.and.saucer.fill", habitType: .quit, defaultGoalTarget: 1, defaultGoalUnit: .count, goalDescription: "Limit coffee to 1 cup daily", defaultQuitHabitType: .limit),
        PresetHabit(name: "Limit Junk Food", iconName: "takeoutbag.and.cup.and.straw.fill", habitType: .quit, defaultGoalTarget: 1, defaultGoalUnit: .count, goalDescription: "Limit junk food to 1 serving daily", defaultQuitHabitType: .limit),
        PresetHabit(name: "Limit Sugar Intake", iconName: "cube.fill", habitType: .quit, defaultGoalTarget: 25, defaultGoalUnit: .grams, goalDescription: "Limit sugar to 25g daily", defaultQuitHabitType: .limit)
    ]
    
    static let allPresets: [PresetHabit] = buildHabits + quitHabits
} 