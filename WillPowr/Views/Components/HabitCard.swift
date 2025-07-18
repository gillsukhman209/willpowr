import SwiftUI

struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @Environment(\.habitService) private var habitService
    @EnvironmentObject private var dateManager: DateManager
    @State private var isPressed = false
    @State private var showingSuccess = false
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Progress Section
                progressSection
                
                // Action Button
                actionSection
            }
            .padding(24)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderGradient, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .alert("Reset Streak?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                habitService?.resetHabitStreak(habit)
            }
        } message: {
            Text("This will reset your streak to 0. This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundGradient)
                    .frame(width: 56, height: 56)
                
                Image(systemName: habit.iconName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .shadow(color: iconShadowColor, radius: 8, x: 0, y: 4)
            
            // Habit Info
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // Type Badge
                    HStack(spacing: 4) {
                        Image(systemName: habit.habitType == .build ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.caption)
                        Text(habit.habitType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(badgeColor)
                    
                    // Completion Status
                    if habit.isGoalMet {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                            Text("Completed")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Menu Button
            Menu {
                Button("View Details") {
                    onTap()
                }
                
                Button("Reset Streak", role: .destructive) {
                    showingConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(habit.streak) \(habit.streak == 1 ? "day" : "days")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Progress for goal-based habits
                if habit.goalUnit != .none {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Today's Progress")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(Int(habit.progressPercentage * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Progress Bar for Goal-Based Habits
            if habit.goalUnit != .none {
                VStack(spacing: 8) {
                    HStack {
                        Text(habit.displayProgress)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        if habit.goalTarget > 0 {
                            Text("\(Int(habit.goalTarget)) \(habit.goalUnit.rawValue)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    ProgressView(value: habit.progressPercentage)
                        .progressViewStyle(CustomProgressViewStyle())
                        .frame(height: 8)
                }
            }
            
            // Motivational Message
            Text(motivationalMessage)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        Button {
            handleAction()
        } label: {
            HStack {
                Image(systemName: actionButtonIcon)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(actionButtonText)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(actionButtonGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: actionButtonShadow, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!habit.canComplete(on: dateManager.currentDate) && habit.habitType == .build)
        .opacity((!habit.canComplete(on: dateManager.currentDate) && habit.habitType == .build) ? 0.6 : 1.0)
        .overlay(
            successOverlay
        )
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            if showingSuccess {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.9), .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Great job!")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showingSuccess)
    }
    
    // MARK: - Computed Properties
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                habit.isGoalMet ? .green.opacity(0.3) : .white.opacity(0.2),
                .clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var iconBackgroundGradient: LinearGradient {
        switch habit.habitType {
        case .build:
            return LinearGradient(
                colors: [.green.opacity(0.8), .green.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .quit:
            return LinearGradient(
                colors: [.red.opacity(0.8), .red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var iconShadowColor: Color {
        switch habit.habitType {
        case .build:
            return .green.opacity(0.3)
        case .quit:
            return .red.opacity(0.3)
        }
    }
    
    private var badgeColor: Color {
        switch habit.habitType {
        case .build:
            return .green
        case .quit:
            return .red
        }
    }
    
    private var motivationalMessage: String {
        if habit.isGoalMet {
            return "Amazing! You've completed today's goal."
        } else if habit.streak == 0 {
            return "Ready to start your journey? You've got this!"
        } else if habit.streak < 7 {
            return "Building momentum! Keep going strong."
        } else if habit.streak < 30 {
            return "Fantastic progress! You're forming a habit."
        } else {
            return "Incredible dedication! You're a habit master."
        }
    }
    
    // MARK: - Action Button Properties
    
    private var actionButtonText: String {
        if habit.habitType == .build {
            return habit.isGoalMet ? "Completed Today" : "Mark Complete"
        } else {
            return "I Failed"
        }
    }
    
    private var actionButtonIcon: String {
        if habit.habitType == .build {
            return habit.isGoalMet ? "checkmark.circle.fill" : "checkmark.circle"
        } else {
            return "xmark.circle"
        }
    }
    
    private var actionButtonGradient: LinearGradient {
        if habit.habitType == .build {
            if habit.isGoalMet {
                return LinearGradient(
                    colors: [.green.opacity(0.8), .green.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            return LinearGradient(
                colors: [.red.opacity(0.8), .red.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var actionButtonShadow: Color {
        if habit.habitType == .build {
            return habit.isGoalMet ? .green.opacity(0.3) : .blue.opacity(0.3)
        } else {
            return .red.opacity(0.3)
        }
    }
    
    // MARK: - Actions
    
    private func handleAction() {
        if habit.habitType == .build {
            if !habit.isGoalMet {
                completeHabit()
            }
        } else {
            failHabit()
        }
    }
    
    private func completeHabit() {
        if !habit.isGoalMet {
            habitService?.completeHabit(habit)
            showSuccessAnimation()
        }
    }
    
    private func failHabit() {
        habitService?.failHabit(habit)
        showSuccessAnimation()
    }
    
    private func showSuccessAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingSuccess = false
            }
        }
    }
}

// MARK: - Custom Progress View Style

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(.ultraThinMaterial)
                .frame(height: 8)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: (configuration.fractionCompleted ?? 0) * 200,
                    height: 8
                )
                .animation(.easeInOut, value: configuration.fractionCompleted)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        HabitCard(habit: Habit(name: "Daily Walk", habitType: .build, iconName: "figure.walk")) {
            print("Tapped habit")
        }
        
        HabitCard(habit: Habit(name: "Quit Social Media", habitType: .quit, iconName: "iphone.slash")) {
            print("Tapped habit")
        }
    }
    .padding(24)
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
    .preferredColorScheme(.dark)
} 