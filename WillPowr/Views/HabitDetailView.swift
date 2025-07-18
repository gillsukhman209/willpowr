import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.habitService) private var habitService
    @EnvironmentObject private var dateManager: DateManager
    @State private var showDeleteConfirmation = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Header
                customNavigationHeader
                
                // Main Content
                if let habitService = habitService {
                    mainContent
                } else {
                    VStack {
                        Text("Service Loading...")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("HabitService is nil")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .confirmationDialog(
            "Delete Habit",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(habit.name)\"? This action cannot be undone.")
        }
        .confirmationDialog(
            "Reset Streak",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                resetHabitStreak()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset your streak to 0. This action cannot be undone.")
        }
        .onAppear {
            print("🔍 HabitDetailView appeared for habit: \(habit.name)")
            print("🔍 HabitService is: \(habitService == nil ? "nil" : "available")")
        }
    }
    
    private var customNavigationHeader: some View {
        HStack {
            Button("Done") {
                dismiss()
            }
            .foregroundColor(.gray)
            .font(.body)
            
            Spacer()
            
            Text("Habit Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.body)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.black)
    }

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Stats
                statsSection
                
                // Reset Action
                resetSection
                
                // Actions
                actionsSection
            }
            .padding(20)
        }
    }
    
    // MARK: - Actions
    
    private func deleteHabit() {
        print("🗑️ Deleting habit: \(habit.name)")
        habitService?.deleteHabit(habit)
        print("🗑️ Habit deleted, dismissing detail view")
        dismiss()
    }
    
    private func resetHabitStreak() {
        habitService?.resetHabitStreak(habit)
    }
    
    @ViewBuilder
    private var errorContent: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Service Not Available")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Unable to load habit service. Please restart the app.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(habitTypeColor)
                    .frame(width: 80, height: 80)
                
                Image(systemName: habit.iconName)
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
            .shadow(color: habitTypeColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 8) {
                Text(habit.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.fallbackPrimaryText)
                
                HStack {
                    Text(habit.habitType.displayName)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(habitTypeColor.opacity(0.2))
                        )
                        .foregroundColor(habitTypeColor)
                }
            }
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            // Current Streak
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.streakFire)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.headline)
                        .foregroundColor(.fallbackSecondaryText)
                    
                    Text("\(habit.streak) days")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.fallbackPrimaryText)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.fallbackGlassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.fallbackGlassBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.fallbackGlassShadow, radius: 4, x: 0, y: 2)
            )
            
            // Longest Streak (Personal Best)
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Best")
                        .font(.headline)
                        .foregroundColor(.fallbackSecondaryText)
                    
                    Text("\(habit.longestStreak) days")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.fallbackPrimaryText)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.fallbackGlassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.fallbackGlassBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.fallbackGlassShadow, radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if habit.habitType == .build {
                if habit.canComplete(on: dateManager.currentDate) {
                    Button {
                        habitService?.completeHabit(habit)
                        dismiss()
                    } label: {
                        actionButtonLabel(
                            icon: "checkmark.circle.fill",
                            text: "Mark Complete",
                            color: .green
                        )
                    }
                } else {
                    actionButtonLabel(
                        icon: "checkmark.circle.fill",
                        text: "Already Completed",
                        color: .green
                    )
                    .opacity(0.6)
                }
            } else {
                // Quit habits - show both success and failure options
                if !habit.isCompleted {
                    // Success button
                    Button {
                        habitService?.markQuitHabitSuccess(habit)
                        dismiss()
                    } label: {
                        actionButtonLabel(
                            icon: "checkmark.circle.fill",
                            text: "I Succeeded Today",
                            color: .green
                        )
                    }
                } else {
                    actionButtonLabel(
                        icon: "checkmark.circle.fill",
                        text: "Already Succeeded Today",
                        color: .green
                    )
                    .opacity(0.6)
                }
                
                // Failure button (always available)
                Button {
                    habitService?.failHabit(habit)
                    dismiss()
                } label: {
                    actionButtonLabel(
                        icon: "xmark.circle.fill",
                        text: "I Failed",
                        color: .red
                    )
                }
            }
        }
    }
    
    private func actionButtonLabel(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.headline)
            Text(text)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        )
    }
    
    private var resetSection: some View {
        Button {
            showResetConfirmation = true
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reset Streak")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Start over from day 0")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var habitTypeColor: Color {
        switch habit.habitType {
        case .build: return .success
        case .quit: return .failure
        }
    }
}

#Preview {
    HabitDetailView(habit: Habit(name: "Walk Daily", habitType: .build, iconName: "figure.walk"))
        .preferredColorScheme(.dark)
} 