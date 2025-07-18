import SwiftUI

struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @Environment(\.habitService) private var habitService
    @State private var isPressed = false
    @State private var showingSuccess = false
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header Row
            headerRow
            
            // Streak Display
            streakDisplay
            
            // Action Button
            if habitService != nil {
                actionButton
            } else {
                disabledActionButton
            }
        }
        .padding(20)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 0.5)
        )
        .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
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
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        HStack(spacing: 12) {
            // Icon
            iconView
            
            // Habit Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.fallbackPrimaryText)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    habitTypeBadge
                    
                    if habit.isCompletedToday {
                        completedBadge
                    }
                }
            }
            
            Spacer()
            
            // Menu Button
            menuButton
        }
    }
    
    // MARK: - Icon View
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 50, height: 50)
            
            Image(systemName: habit.iconName)
                .font(.title2)
                .foregroundColor(.white)
        }
        .shadow(color: iconBackgroundColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Habit Type Badge
    
    private var habitTypeBadge: some View {
        Text(habit.habitType.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(badgeBackgroundColor)
            )
            .foregroundColor(badgeTextColor)
    }
    
    // MARK: - Completed Badge
    
    private var completedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
            Text("Done")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.success)
    }
    
    // MARK: - Menu Button
    
    private var menuButton: some View {
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
                .foregroundColor(.fallbackSecondaryText)
                .padding(8)
        }
    }
    
    // MARK: - Streak Display
    
    private var streakDisplay: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(streakColor)
                
                Text("\(habit.streak)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.fallbackPrimaryText)
                
                Text(habit.streak == 1 ? "day" : "days")
                    .font(.headline)
                    .foregroundColor(.fallbackSecondaryText)
                
                Spacer()
            }
            
            HStack {
                Text(habit.streakText)
                    .font(.subheadline)
                    .foregroundColor(.fallbackSecondaryText)
                
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button {
            handleAction()
        } label: {
            HStack {
                Image(systemName: actionButtonIcon)
                    .font(.headline)
                
                Text(actionButtonText)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(actionButtonColor)
                    .shadow(color: actionButtonColor.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!habit.canCompleteToday && habit.habitType == .build)
        .opacity((!habit.canCompleteToday && habit.habitType == .build) ? 0.6 : 1.0)
        .overlay(
            successOverlay
        )
    }
    
    // MARK: - Disabled Action Button
    
    private var disabledActionButton: some View {
        Button {
            // No action for disabled button
        } label: {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.headline)
                Text("Service Unavailable")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray)
                    .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(true)
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            if showingSuccess {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.success)
                    .overlay(
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.headline)
                            Text("Great job!")
                                .font(.headline)
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
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.fallbackGlassBackground,
                Color.fallbackGlassBackground.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderColor: Color {
        habit.isCompletedToday ? .success.opacity(0.3) : .fallbackGlassBorder
    }
    
    private var shadowColor: Color {
        habit.isCompletedToday ? .success.opacity(0.2) : .fallbackGlassShadow
    }
    
    private var iconBackgroundColor: Color {
        switch habit.habitType {
        case .build:
            return .success
        case .quit:
            return .failure
        }
    }
    
    private var badgeBackgroundColor: Color {
        switch habit.habitType {
        case .build:
            return .success.opacity(0.2)
        case .quit:
            return .failure.opacity(0.2)
        }
    }
    
    private var badgeTextColor: Color {
        switch habit.habitType {
        case .build:
            return .success
        case .quit:
            return .failure
        }
    }
    
    private var streakColor: Color {
        Color.streakColor(for: habit.streak)
    }
    
    private var actionButtonText: String {
        if habit.habitType == .build {
            return habit.isCompletedToday ? "Completed" : "Mark Complete"
        } else {
            return "I Failed"
        }
    }
    
    private var actionButtonIcon: String {
        if habit.habitType == .build {
            return habit.isCompletedToday ? "checkmark.circle.fill" : "checkmark.circle"
        } else {
            return "xmark.circle"
        }
    }
    
    private var actionButtonColor: Color {
        if habit.habitType == .build {
            return habit.isCompletedToday ? .success : .blue
        } else {
            return .failure
        }
    }
    
    // MARK: - Actions
    
    private func handleAction() {
        if habit.habitType == .build {
            if !habit.isCompletedToday {
                completeHabit()
            }
        } else {
            failHabit()
        }
    }
    
    private func completeHabit() {
        habitService?.completeHabit(habit)
        showSuccessAnimation()
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

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HabitCard(habit: Habit(name: "Walk Daily", habitType: .build, iconName: "figure.walk")) {
            print("Tapped habit")
        }
        
        HabitCard(habit: Habit(name: "Quit Social Media", habitType: .quit, iconName: "iphone.slash")) {
            print("Tapped habit")
        }
    }
    .padding()
    .background(Color.fallbackPrimaryBackground)
    .preferredColorScheme(.dark)
} 