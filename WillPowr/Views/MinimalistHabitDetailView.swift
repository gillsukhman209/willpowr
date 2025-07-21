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
        VStack(spacing: 12) {
            if habit.goalUnit == .none {
                Button {
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
            } else {
                Button {
                    // TODO: Show progress input sheet
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        
                        Text("Log Progress")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.electricBlue)
                    .cornerRadius(12)
                }
            }
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