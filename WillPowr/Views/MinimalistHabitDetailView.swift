import SwiftUI

struct MinimalistHabitDetailView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var habitService: HabitService
    @EnvironmentObject private var dateManager: DateManager
    @State private var showDeleteConfirmation = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        habitHeader
                        
                        statsSection
                        
                        if habit.goalUnit != .none {
                            progressSection
                        }
                        
                        actionsSection
                        
                        dangerZone
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    private var habitHeader: some View {
        VStack(spacing: 15) {
            Image(systemName: habit.iconName)
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.electricBlue)
                .padding()
                .background(
                    Circle()
                        .fill(DesignTokens.Colors.electricBlue.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(DesignTokens.Colors.electricBlue.opacity(0.3), lineWidth: 1)
                        )
                )
            
            Text(habit.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if habit.streak > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(habit.streak) day streak")
                        .foregroundColor(.white.opacity(0.8))
                }
                .font(.subheadline)
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            statCard(
                title: "Total Days",
                value: "\(getCompletionDatesCount())",
                icon: "checkmark.circle.fill",
                color: DesignTokens.Colors.neonGreen
            )
            
            statCard(
                title: "Best Streak",
                value: "\(habit.longestStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            statCard(
                title: "Success Rate",
                value: "\(Int(calculateSuccessRate()))%",
                icon: "chart.line.uptrend.xyaxis",
                color: DesignTokens.Colors.electricBlue
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text("\(Int(habit.currentProgress))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("/ \(Int(habit.goalTarget)) \(habit.goalUnit.displayName)")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                if habit.currentProgress >= habit.goalTarget {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(DesignTokens.Colors.neonGreen)
                }
            }
            
            ProgressView(value: habit.currentProgress, total: habit.goalTarget)
                .tint(DesignTokens.Colors.electricBlue)
                .scaleEffect(y: 2)
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 15) {
            if habit.isAbstinenceHabit {
                // Abstinence quit habits - clean/failed buttons
                abstinenceHabitControls
            } else if habit.isLimitHabit {
                // Limit quit habits - usage tracking
                limitHabitControls
            } else if habit.habitType == .build && habit.goalUnit == .none {
                // Binary build habits - simple toggle
                binaryHabitToggle
            } else if habit.canUseAutoTracking {
                // Automatic habits - read-only display
                automaticTrackingDisplay
            } else {
                // Manual build habits - interactive progress controls
                manualProgressControls
            }
        }
    }
    
    private var binaryHabitToggle: some View {
        Button {
            print("🔘 Binary habit toggle tapped for: \(habit.name)")
            habitService.completeHabit(habit)
        } label: {
            HStack {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                
                Text(habit.isCompleted ? "Completed Today" : "Mark as Complete")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                habit.isCompleted ?
                DesignTokens.Colors.neonGreen :
                DesignTokens.Colors.electricBlue
            )
            .cornerRadius(12)
        }
    }
    
    private var abstinenceHabitControls: some View {
        VStack(spacing: 12) {
            // Current status display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Status")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(habit.quitHabitStatusText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(habit.isSuccessfulToday ? DesignTokens.Colors.neonGreen : .orange)
                }
                
                Spacer()
                
                if habit.cleanDaysStreak > 0 {
                    VStack(spacing: 2) {
                        Text("\(habit.cleanDaysStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.Colors.neonGreen)
                        Text("clean days")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    // Mark as successful (stayed clean)
                    print("🔘 Stayed Clean button tapped for: \(habit.name)")
                    habitService.markQuitHabitSuccess(habit)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Stayed Clean")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        habit.isSuccessfulToday ?
                        DesignTokens.Colors.neonGreen :
                        DesignTokens.Colors.electricBlue
                    )
                    .cornerRadius(12)
                }
                .disabled(habit.hasInteractedToday)
                
                Button {
                    // Mark as failed
                    print("🔘 I Failed button tapped for: \(habit.name)")
                    habitService.failHabit(habit)
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                        Text("I Failed")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red.opacity(0.8))
                    .cornerRadius(12)
                }
                .disabled(habit.hasInteractedToday)
            }
        }
    }
    
    private var limitHabitControls: some View {
        VStack(spacing: 12) {
            // Current usage display
            currentProgressDisplay
            
            // Quick add buttons for logging usage
            VStack(spacing: 8) {
                Text("Log Usage")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(getQuickAddValues(), id: \.self) { value in
                        limitUsageButton(value: value)
                    }
                }
            }
            
            // Goal status indicator
            limitStatusIndicator
        }
    }
    
    private func limitUsageButton(value: Double) -> some View {
        Button {
            print("🔘 Limit usage button tapped for: \(habit.name), adding progress: \(value)")
            habitService.addProgressToHabit(habit, progress: value)
        } label: {
            Text("+\(formatValue(value))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    habit.currentProgress + value > habit.goalTarget ?
                    Color.red.opacity(0.3) :
                    DesignTokens.Colors.electricBlue.opacity(0.3)
                )
                .cornerRadius(8)
        }
    }
    
    private var limitStatusIndicator: some View {
        HStack {
            Image(systemName: habit.isSuccessfulToday ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(habit.isSuccessfulToday ? DesignTokens.Colors.neonGreen : .orange)
            
            Text(habit.isSuccessfulToday ? "Under your daily limit" : "Over your daily limit")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(habit.isSuccessfulToday ? DesignTokens.Colors.neonGreen : .orange)
            
            Spacer()
        }
        .padding()
        .background(
            (habit.isSuccessfulToday ? DesignTokens.Colors.neonGreen : Color.orange).opacity(0.1)
        )
        .cornerRadius(12)
    }
    
    private var automaticTrackingDisplay: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(DesignTokens.Colors.electricBlue)
                Text("Automatically tracked")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            if habit.isGoalMet {
                goalCompletedIndicator
            }
        }
    }
    
    private var manualProgressControls: some View {
        VStack(spacing: 12) {
            // Current progress display
            currentProgressDisplay
            
            // Quick action buttons based on goal unit
            quickActionButtons
            
            // Goal completion indicator
            if habit.isGoalMet {
                goalCompletedIndicator
            }
        }
    }
    
    private var currentProgressDisplay: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress Today")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(formatValue(habit.currentProgress)) / \(formatValue(habit.goalTarget)) \(habit.goalUnit.displayName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            CircularProgressView(
                progress: habit.progressPercentage,
                color: DesignTokens.Colors.electricBlue
            )
            .frame(width: 40, height: 40)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var quickActionButtons: some View {
        VStack(spacing: 8) {
            Text("Quick Add")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(getQuickAddValues(), id: \.self) { value in
                    quickActionButton(value: value)
                }
            }
        }
    }
    
    private func quickActionButton(value: Double) -> some View {
        Button {
            print("🔘 Quick action button tapped for: \(habit.name), adding progress: \(value)")
            habitService.addProgressToHabit(habit, progress: value)
        } label: {
            Text("+\(formatValue(value))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(DesignTokens.Colors.electricBlue.opacity(0.3))
                .cornerRadius(8)
        }
    }
    
    private var goalCompletedIndicator: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignTokens.Colors.neonGreen)
            Text("Goal completed!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignTokens.Colors.neonGreen)
            Spacer()
        }
        .padding()
        .background(DesignTokens.Colors.neonGreen.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func getQuickAddValues() -> [Double] {
        switch habit.goalUnit {
        case .steps:
            return [1000, 2000, 5000, 10000]
        case .minutes:
            return [5, 10, 15, 30]
        case .hours:
            return [0.5, 1, 2, 3]
        case .liters:
            return [0.25, 0.5, 1, 1.5]
        case .glasses:
            return [1, 2, 3, 4]
        case .grams:
            return [10, 25, 50, 100]
        case .count:
            return [1, 5, 10, 25]
        case .none:
            return []
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    private var dangerZone: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.vertical)
            
            Button {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Progress")
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Habit")
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .alert("Delete Habit?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                habitService.deleteHabit(habit)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Reset Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                habitService.resetHabitStreak(habit)
            }
        } message: {
            Text("All your progress will be lost.")
        }
    }
    
    private func calculateSuccessRate() -> Double {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: habit.createdDate, to: Date()).day ?? 1
        return Double(getCompletionDatesCount()) / Double(max(daysSinceCreation, 1)) * 100
    }
    
    private func getCompletionDatesCount() -> Int {
        // Calculate based on habit streak and longestStreak
        // This is a simplified calculation - could be improved with a proper completion dates array
        return max(habit.streak, habit.longestStreak)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}