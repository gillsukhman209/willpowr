import SwiftUI

struct DebugHistoryPanel: View {
    @EnvironmentObject var habitService: HabitService
    @EnvironmentObject var dateManager: DateManager
    @State private var selectedDate = Date()
    @State private var selectedHabit: Habit?
    @State private var customProgress: Double = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("🔧 Debug History Panel")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("Testing Mode")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Date Travel Section
            VStack(alignment: .leading, spacing: 12) {
                Text("📅 Date Travel")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                DatePicker("Travel to Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                HStack(spacing: 12) {
                    Button("Yesterday") {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: dateManager.currentDate) ?? dateManager.currentDate
                        travelToDate()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Last Week") {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: dateManager.currentDate) ?? dateManager.currentDate
                        travelToDate()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Last Month") {
                        selectedDate = Calendar.current.date(byAdding: .day, value: -30, to: dateManager.currentDate) ?? dateManager.currentDate
                        travelToDate()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Reset to Real Today") {
                        dateManager.resetToToday()
                        selectedDate = dateManager.currentDate
                        habitService.refreshHabitStatesForCurrentDate()
                        showAlert(message: "🔄 Reset to real today")
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button("🚀 Travel to Selected Date") {
                    travelToDate()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Current Status
            VStack(alignment: .leading, spacing: 8) {
                Text("📊 Current Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Text("Debug Date:")
                    Spacer()
                    Text(dateManager.formatDebugDate())
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Habits Count:")
                    Spacer()
                    Text("\(habitService.habits.count)")
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Progress Manipulation
            if !habitService.habits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("🎚️ Progress Manipulation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Select Habit", selection: $selectedHabit) {
                        Text("Select a habit...").tag(nil as Habit?)
                        ForEach(habitService.habits, id: \.id) { habit in
                            Text(habit.name).tag(habit as Habit?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if let habit = selectedHabit {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Progress: \(Int(customProgress))")
                                Spacer()
                                Text("Goal: \(Int(habit.goalTarget)) \(habit.goalUnit.displayName)")
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $customProgress, in: 0...max(habit.goalTarget * 2, 10000), step: 1)
                                .onAppear {
                                    customProgress = habit.currentProgress
                                }
                            
                            HStack(spacing: 12) {
                                Button("Set Progress") {
                                    setCustomProgress()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Complete Goal") {
                                    customProgress = habit.goalTarget
                                    setCustomProgress()
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Reset to 0") {
                                    customProgress = 0
                                    setCustomProgress()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Sample Data Generation
            VStack(alignment: .leading, spacing: 12) {
                Text("🔄 Sample Data")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    Button("Generate 7 Days of Sample History") {
                        generateSampleHistory(days: 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Generate 30 Days of Sample History") {
                        generateSampleHistory(days: 30)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("🗑️ Clear All History") {
                        clearAllHistory()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .alert("Debug Action", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            selectedDate = dateManager.currentDate
        }
    }
    
    // MARK: - Debug Actions
    
    private func travelToDate() {
        dateManager.setDebugDate(selectedDate)
        habitService.refreshHabitStatesForCurrentDate()
        showAlert(message: "🚀 Traveled to \(DateFormatter.mediumDate.string(from: selectedDate))")
    }
    
    private func setCustomProgress() {
        guard let habit = selectedHabit else { return }
        
        habitService.updateHabitProgress(habit, progress: customProgress)
        showAlert(message: "📊 Set \(habit.name) progress to \(Int(customProgress))")
    }
    
    private func generateSampleHistory(days: Int) {
        guard !habitService.habits.isEmpty else {
            showAlert(message: "❌ No habits found. Create a habit first.")
            return
        }
        
        let calendar = Calendar.current
        var entriesCreated = 0
        
        for habit in habitService.habits {
            for dayOffset in 1...days {
                if let pastDate = calendar.date(byAdding: .day, value: -dayOffset, to: dateManager.currentDate) {
                    // Generate realistic progress
                    let progressVariation = Double.random(in: 0.3...1.5)
                    let progress = habit.goalTarget * progressVariation
                    let isCompleted = progress >= habit.goalTarget
                    
                    // Create history entry
                    createDebugHistoryEntry(for: habit, on: pastDate, progress: progress, completed: isCompleted)
                    entriesCreated += 1
                }
            }
        }
        
        showAlert(message: "✅ Generated \(entriesCreated) sample history entries for \(days) days")
    }
    
    private func clearAllHistory() {
        for habit in habitService.habits {
            // Remove all entries
            let entries = habit.entries
            for entry in entries {
                habitService.deleteHistoryEntry(entry)
            }
        }
        showAlert(message: "🗑️ Cleared all history entries")
    }
    
    private func createDebugHistoryEntry(for habit: Habit, on date: Date, progress: Double, completed: Bool) {
        let targetDate = Calendar.current.startOfDay(for: date)
        
        // Check if entry already exists
        if let existingEntry = habit.entryFor(date: targetDate) {
            // Update existing
            existingEntry.progress = progress
            existingEntry.isCompleted = completed
        } else {
            // Create new entry
            let entry = HabitEntry(
                habitId: habit.id,
                date: targetDate,
                progress: progress,
                goalTarget: habit.goalTarget,
                goalUnit: habit.goalUnit,
                habitType: habit.habitType,
                quitHabitType: habit.quitHabitType,
                isCompleted: completed
            )
            entry.habit = habit
            habit.entries.append(entry)
            // modelContext is handled internally by HabitService
        }
        
        // Save changes
        try? habitService.saveChanges()
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// DateFormatter.mediumDate extension is already defined in HealthKitService

#Preview {
    DebugHistoryPanel()
}
