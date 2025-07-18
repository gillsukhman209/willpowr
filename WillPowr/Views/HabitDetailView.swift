import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var habitService: HabitService
    @EnvironmentObject private var dateManager: DateManager
    @State private var showDeleteConfirmation = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            // Premium Background with Gradient (matching main app)
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating orbs for depth (matching main app)
            FloatingOrbs()
            
            VStack(spacing: 0) {
                // Premium Navigation Header
                premiumNavigationHeader
                
                // Main Content
                ScrollView {
                        VStack(spacing: 24) {
                            // Hero Section
                            heroSection
                            
                            // Stats Section
                            statsSection
                            
                            // Progress Section (if applicable)
                            if habit.goalUnit != .none {
                                progressSection
                            }
                            
                            // Actions Section
                            actionsSection
                            
                            // Danger Zone
                            dangerZone
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
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
            print("🔍 HabitService is: available")
        }
    }
    
    // MARK: - Header
    
    private var premiumNavigationHeader: some View {
        ZStack {
            // Background with blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.white.opacity(0.1), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                )
            
            HStack {
                Button("Done") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dismiss()
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text("Habit Details")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 60)
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Icon with dynamic background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [habitTypeColor, habitTypeColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: habitTypeColor.opacity(0.4), radius: 20, x: 0, y: 8)
                
                Image(systemName: habit.iconName)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text(habit.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    // Habit Type Badge
                    HStack(spacing: 6) {
                        Image(systemName: habit.habitType == .build ? "plus.circle.fill" : "minus.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text(habit.habitType.displayName)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(habitTypeColor.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(habitTypeColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundColor(habitTypeColor)
                    
                    // Custom badge if applicable
                    if habit.isCustom {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .medium))
                            Text("Custom")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(.orange.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Current Streak
                DetailStatCard(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Current Streak",
                    value: "\(habit.streak)",
                    subtitle: habit.streak == 1 ? "day" : "days",
                    backgroundGradient: LinearGradient(
                        colors: [.orange.opacity(0.1), .red.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Personal Best
                DetailStatCard(
                    icon: "trophy.fill",
                    iconColor: .yellow,
                    title: "Personal Best",
                    value: "\(habit.longestStreak)",
                    subtitle: habit.longestStreak == 1 ? "day" : "days",
                    backgroundGradient: LinearGradient(
                        colors: [.yellow.opacity(0.1), .orange.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            
            // Status Card
            HStack(spacing: 16) {
                Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(habit.isCompleted ? .green : .orange)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Today's Status")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(habit.isCompleted ? "Completed" : "Pending")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(habit.isCompleted ? .green : .orange)
                    }
                    
                    Text(habit.canCompleteToday ? "Ready to complete" : "Already completed")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
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
    }
    
    // MARK: - Progress Section
    
    @ViewBuilder
    private var progressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(habitTypeColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: habit.progressPercentage)
                        .stroke(
                            LinearGradient(
                                colors: [habitTypeColor, habitTypeColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(Int(habit.progressPercentage * 100))%")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Complete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Progress Details
                VStack(spacing: 12) {
                    HStack {
                        Text("Goal:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(habit.displayProgress)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    if let description = habit.goalDescription {
                        Text(description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
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
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Actions")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 12) {
                if habit.habitType == .build {
                    if habit.canComplete(on: dateManager.currentDate) {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                habitService.completeHabit(habit)
                                dismiss()
                            }
                        } label: {
                            PremiumActionButton(
                                icon: "checkmark.circle.fill",
                                text: "Mark Complete",
                                color: .green,
                                isEnabled: true
                            )
                        }
                    } else {
                        PremiumActionButton(
                            icon: "checkmark.circle.fill",
                            text: "Already Completed",
                            color: .green,
                            isEnabled: false
                        )
                    }
                } else {
                    // Quit habits
                    if !habit.isCompleted {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                habitService.markQuitHabitSuccess(habit)
                                dismiss()
                            }
                        } label: {
                            PremiumActionButton(
                                icon: "checkmark.circle.fill",
                                text: "I Succeeded Today",
                                color: .green,
                                isEnabled: true
                            )
                        }
                    } else {
                        PremiumActionButton(
                            icon: "checkmark.circle.fill",
                            text: "Succeeded Today",
                            color: .green,
                            isEnabled: false
                        )
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            habitService.failHabit(habit)
                            dismiss()
                        }
                    } label: {
                        PremiumActionButton(
                            icon: "xmark.circle.fill",
                            text: "I Failed",
                            color: .red,
                            isEnabled: true
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Danger Zone
    
    private var dangerZone: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Danger Zone")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button {
                    showResetConfirmation = true
                } label: {
                    DangerButton(
                        icon: "arrow.counterclockwise",
                        title: "Reset Streak",
                        description: "Start over from day 0",
                        color: .orange
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var errorStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
            
            VStack(spacing: 12) {
                Text("Service Unavailable")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Unable to load habit service. Please restart the app.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Actions
    
    private func deleteHabit() {
        print("🗑️ Deleting habit: \(habit.name)")
        habitService.deleteHabit(habit)
        print("🗑️ Habit deleted, dismissing detail view")
        dismiss()
    }
    
    private func resetHabitStreak() {
        habitService.resetHabitStreak(habit)
    }
    
    // MARK: - Computed Properties
    
    private var habitTypeColor: Color {
        switch habit.habitType {
        case .build: return .green
        case .quit: return .red
        }
    }
}

// MARK: - Supporting Views

struct DetailStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let backgroundGradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
                
                HStack {
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct PremiumActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
            
            Text(text)
                .font(.system(size: 18, weight: .semibold))
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    isEnabled ?
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(isEnabled ? 0.2 : 0.1), lineWidth: 1)
                )
                .shadow(
                    color: isEnabled ? color.opacity(0.3) : .clear,
                    radius: isEnabled ? 8 : 0,
                    x: 0,
                    y: isEnabled ? 4 : 0
                )
        )
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

struct DangerButton: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}



#Preview {
    HabitDetailView(habit: Habit(name: "Meditate", habitType: .build, iconName: "brain.head.profile"))
        .preferredColorScheme(.dark)
} 