import Foundation
import Combine

// MARK: - Dashboard View Model
@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var habits: [HabitModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingAddHabit = false
    @Published var selectedHabit: HabitModel?
    @Published var showingHabitDetail = false
    
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var buildHabits: [HabitModel] {
        habits.filter { $0.type == .build }
    }
    
    var quitHabits: [HabitModel] {
        habits.filter { $0.type == .quit }
    }
    
    var totalActiveHabits: Int {
        habits.filter { $0.isActive }.count
    }
    
    var totalStreakDays: Int {
        habits.reduce(0) { $0 + $1.streakCount }
    }
    
    var hasHabits: Bool {
        !habits.isEmpty
    }
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        setupObservers()
        loadHabits()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe data service changes if it's the shared instance
        if let sharedDataService = dataService as? DataService {
            sharedDataService.$habits
                .assign(to: &$habits)
            
            sharedDataService.$isLoading
                .assign(to: &$isLoading)
            
            sharedDataService.$error
                .assign(to: &$error)
        }
    }
    
    // MARK: - Data Loading
    func loadHabits() {
        Task {
            await loadHabitsAsync()
        }
    }
    
    private func loadHabitsAsync() async {
        isLoading = true
        error = nil
        
        do {
            let loadedHabits = try await dataService.loadHabits()
            habits = loadedHabits
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Habit Actions
    func completeHabit(_ habit: HabitModel) {
        guard habit.canCompleteToday else { return }
        
        Task {
            do {
                let updatedHabit = try await dataService.completeHabit(habit)
                updateHabitInList(updatedHabit)
                
                // Haptic feedback for completion
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
            } catch {
                self.error = error
            }
        }
    }
    
    func failHabit(_ habit: HabitModel) {
        guard habit.type == .quit else { return }
        
        Task {
            do {
                let updatedHabit = try await dataService.resetHabitStreak(habit)
                updateHabitInList(updatedHabit)
                
                // Haptic feedback for failure
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                
            } catch {
                self.error = error
            }
        }
    }
    
    func deleteHabit(_ habit: HabitModel) {
        Task {
            do {
                try await dataService.deleteHabit(habit)
                habits.removeAll { $0.id == habit.id }
            } catch {
                self.error = error
            }
        }
    }
    
    func addHabit(_ habit: HabitModel) {
        Task {
            do {
                try await dataService.saveHabit(habit)
                habits.append(habit)
            } catch {
                self.error = error
            }
        }
    }
    
    // MARK: - UI Actions
    func showAddHabit() {
        showingAddHabit = true
    }
    
    func hideAddHabit() {
        showingAddHabit = false
    }
    
    func selectHabit(_ habit: HabitModel) {
        selectedHabit = habit
        showingHabitDetail = true
    }
    
    func hideHabitDetail() {
        showingHabitDetail = false
        selectedHabit = nil
    }
    
    // MARK: - Helper Methods
    private func updateHabitInList(_ updatedHabit: HabitModel) {
        if let index = habits.firstIndex(where: { $0.id == updatedHabit.id }) {
            habits[index] = updatedHabit
        }
    }
    
    func refreshHabits() {
        loadHabits()
    }
    
    // MARK: - Statistics
    func getStreakForHabit(_ habit: HabitModel) -> Int {
        return habit.streakCount
    }
    
    func getCompletionStatusForHabit(_ habit: HabitModel) -> String {
        switch habit.type {
        case .build:
            return habit.canCompleteToday ? "Ready to complete" : "Completed today"
        case .quit:
            return "Streak: \(habit.streakCount) days"
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        error = nil
    }
    
    func handleError(_ error: Error) {
        self.error = error
    }
}

// MARK: - Habit Creation View Model
@MainActor
class AddHabitViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedType: HabitType = .build
    @Published var habitName = ""
    @Published var selectedCategory: HabitCategory = .health
    @Published var selectedSystemImage = "star.fill"
    @Published var showingCustomHabit = false
    @Published var isCreating = false
    @Published var error: Error?
    
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol
    
    // MARK: - Computed Properties
    var presetHabits: [HabitModel] {
        HabitModel.presetHabits.filter { $0.type == selectedType }
    }
    
    var canCreateHabit: Bool {
        !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
    }
    
    // MARK: - Actions
    func selectHabitType(_ type: HabitType) {
        selectedType = type
    }
    
    func selectPresetHabit(_ habit: HabitModel) {
        habitName = habit.name
        selectedCategory = habit.category
        selectedSystemImage = habit.systemImageName
    }
    
    func showCustomHabit() {
        showingCustomHabit = true
        clearForm()
    }
    
    func hideCustomHabit() {
        showingCustomHabit = false
        clearForm()
    }
    
    func createHabit() async throws -> HabitModel {
        guard canCreateHabit else {
            throw ValidationError.invalidHabitName
        }
        
        isCreating = true
        error = nil
        
        let newHabit = HabitModel(
            name: habitName.trimmingCharacters(in: .whitespacesAndNewlines),
            type: selectedType,
            category: selectedCategory,
            systemImageName: selectedSystemImage
        )
        
        do {
            try await dataService.saveHabit(newHabit)
            clearForm()
            isCreating = false
            return newHabit
        } catch {
            self.error = error
            isCreating = false
            throw error
        }
    }
    
    func createPresetHabit(_ habit: HabitModel) async throws -> HabitModel {
        isCreating = true
        error = nil
        
        let newHabit = HabitModel(
            name: habit.name,
            type: selectedType,
            category: habit.category,
            systemImageName: habit.systemImageName
        )
        
        do {
            try await dataService.saveHabit(newHabit)
            isCreating = false
            return newHabit
        } catch {
            self.error = error
            isCreating = false
            throw error
        }
    }
    
    // MARK: - Helper Methods
    private func clearForm() {
        habitName = ""
        selectedCategory = .health
        selectedSystemImage = "star.fill"
    }
    
    func clearError() {
        error = nil
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError {
    case invalidHabitName
    case habitAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .invalidHabitName:
            return "Please enter a valid habit name"
        case .habitAlreadyExists:
            return "A habit with this name already exists"
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension DashboardViewModel {
    static var preview: DashboardViewModel {
        let mockService = MockDataService()
        let viewModel = DashboardViewModel(dataService: mockService)
        
        // Add some sample habits
        viewModel.habits = [
            HabitModel(
                name: "Morning Walk",
                type: .build,
                category: .fitness,
                systemImageName: "figure.walk",
                streakCount: 5,
                lastCompletedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
            ),
            HabitModel(
                name: "Quit Social Media",
                type: .quit,
                category: .social,
                systemImageName: "iphone.slash",
                streakCount: 12,
                lastCompletedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
            ),
            HabitModel(
                name: "Read Books",
                type: .build,
                category: .productivity,
                systemImageName: "book.fill",
                streakCount: 3
            )
        ]
        
        return viewModel
    }
}

extension AddHabitViewModel {
    static var preview: AddHabitViewModel {
        let mockService = MockDataService()
        return AddHabitViewModel(dataService: mockService)
    }
}
#endif 