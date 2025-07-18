import SwiftUI

// MARK: - Habit Card View
struct HabitCardView: View {
    let habit: HabitModel
    let onComplete: () -> Void
    let onFail: (() -> Void)?
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    @State private var completionAnimation = false
    
    init(
        habit: HabitModel,
        onComplete: @escaping () -> Void,
        onFail: (() -> Void)? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.habit = habit
        self.onComplete = onComplete
        self.onFail = onFail
        self.onTap = onTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Content Section
            contentSection
            
            // Action Button Section
            actionButtonSection
        }
        .glassCard(cornerRadius: CornerRadius.lg, shadowStyle: ShadowStyle.medium)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            if let onTap = onTap {
                onTap()
            }
        }
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            perform: {},
            onPressingChanged: { pressing in
                isPressed = pressing
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // Habit Icon & Name
            HStack(spacing: Spacing.sm) {
                Image(systemName: habit.systemImageName)
                    .font(.title2)
                    .foregroundColor(habit.type == .build ? .buildHabit : .quitHabit)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text(habit.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Streak Counter
            StreakCounterView(count: habit.streakCount, type: habit.type)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: Spacing.sm) {
            // Streak Progress
            streakProgressView
            
            // Status Text
            statusView
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
    
    // MARK: - Streak Progress View
    private var streakProgressView: some View {
        VStack(spacing: Spacing.xs) {
            HStack {
                Text("Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(habit.streakCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(habit.type == .build ? .buildHabit : .quitHabit)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(Color.tertiaryBackground)
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: CornerRadius.xs)
                        .fill(
                            LinearGradient(
                                colors: habit.type == .build ? 
                                    [.buildHabit, .buildHabitLight] : 
                                    [.quitHabit, .quitHabitLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: progressWidth(for: geometry.size.width),
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.3), value: habit.streakCount)
                }
            }
            .frame(height: 4)
        }
    }
    
    // MARK: - Status View
    private var statusView: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            if let lastCompleted = habit.lastCompletedDate {
                Text(lastCompletedText(lastCompleted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Action Button Section
    private var actionButtonSection: some View {
        VStack(spacing: Spacing.sm) {
            Divider()
                .background(Color.glassStroke)
            
            HStack(spacing: Spacing.md) {
                // Main Action Button
                Button(action: {
                    handleMainAction()
                }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: habit.completionButtonSystemImage)
                            .font(.callout)
                        
                        Text(habit.completionButtonText)
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(buttonBackgroundColor)
                    )
                    .foregroundColor(buttonForegroundColor)
                    .scaleEffect(completionAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: completionAnimation)
                }
                .disabled(!canPerformAction)
                .opacity(canPerformAction ? 1.0 : 0.6)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
    }
    
    // MARK: - Computed Properties
    private var statusIcon: String {
        switch habit.type {
        case .build:
            return habit.canCompleteToday ? "checkmark.circle" : "checkmark.circle.fill"
        case .quit:
            return "flame.fill"
        }
    }
    
    private var statusText: String {
        switch habit.type {
        case .build:
            return habit.canCompleteToday ? "Ready to complete" : "Completed today"
        case .quit:
            return "Days without \(habit.name.lowercased())"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch habit.type {
        case .build:
            return habit.canCompleteToday ? .buildHabit : .tertiaryBackground
        case .quit:
            return .quitHabit.opacity(0.8)
        }
    }
    
    private var buttonForegroundColor: Color {
        switch habit.type {
        case .build:
            return habit.canCompleteToday ? .white : .secondary
        case .quit:
            return .white
        }
    }
    
    private var canPerformAction: Bool {
        switch habit.type {
        case .build:
            return habit.canCompleteToday
        case .quit:
            return true
        }
    }
    
    private var accessibilityLabel: String {
        "\(habit.name), \(habit.type.displayName) habit, \(habit.streakCount) day streak"
    }
    
    private var accessibilityHint: String {
        switch habit.type {
        case .build:
            return habit.canCompleteToday ? "Double tap to complete" : "Already completed today"
        case .quit:
            return "Double tap if you failed this habit"
        }
    }
    
    // MARK: - Helper Methods
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let maxStreak: CGFloat = 30 // Show full progress at 30 days
        let progress = min(CGFloat(habit.streakCount) / maxStreak, 1.0)
        return totalWidth * progress
    }
    
    private func lastCompletedText(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.style = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func handleMainAction() {
        // Trigger completion animation
        withAnimation(.easeInOut(duration: 0.2)) {
            completionAnimation = true
        }
        
        // Reset animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                completionAnimation = false
            }
        }
        
        // Perform action based on habit type
        switch habit.type {
        case .build:
            if habit.canCompleteToday {
                onComplete()
            }
        case .quit:
            onFail?()
        }
    }
}

// MARK: - Compact Habit Card View
struct CompactHabitCardView: View {
    let habit: HabitModel
    let onComplete: () -> Void
    let onFail: (() -> Void)?
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            Image(systemName: habit.systemImageName)
                .font(.title3)
                .foregroundColor(habit.type == .build ? .buildHabit : .quitHabit)
                .frame(width: 24, height: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(habit.streakCount) day streak")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            Button(action: {
                switch habit.type {
                case .build:
                    onComplete()
                case .quit:
                    onFail?()
                }
            }) {
                Image(systemName: habit.completionButtonSystemImage)
                    .font(.callout)
                    .foregroundColor(habit.type == .build ? .buildHabit : .quitHabit)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.tertiaryBackground)
                    )
            }
            .disabled(!canPerformAction)
            .opacity(canPerformAction ? 1.0 : 0.6)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard(cornerRadius: CornerRadius.md, shadowStyle: ShadowStyle.soft)
    }
    
    private var canPerformAction: Bool {
        switch habit.type {
        case .build:
            return habit.canCompleteToday
        case .quit:
            return true
        }
    }
}

// MARK: - Preview Provider
#if DEBUG
struct HabitCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Build Habit - Can Complete
            HabitCardView(
                habit: HabitModel(
                    name: "Morning Walk",
                    type: .build,
                    category: .fitness,
                    systemImageName: "figure.walk",
                    streakCount: 5
                ),
                onComplete: {}
            )
            
            // Build Habit - Already Completed
            HabitCardView(
                habit: HabitModel(
                    name: "Read Books",
                    type: .build,
                    category: .productivity,
                    systemImageName: "book.fill",
                    streakCount: 12,
                    lastCompletedDate: Date()
                ),
                onComplete: {}
            )
            
            // Quit Habit
            HabitCardView(
                habit: HabitModel(
                    name: "Quit Social Media",
                    type: .quit,
                    category: .social,
                    systemImageName: "iphone.slash",
                    streakCount: 8
                ),
                onComplete: {},
                onFail: {}
            )
            
            // Compact View
            CompactHabitCardView(
                habit: HabitModel(
                    name: "Meditate",
                    type: .build,
                    category: .mindfulness,
                    systemImageName: "leaf.fill",
                    streakCount: 3
                ),
                onComplete: {}
            )
        }
        .padding()
        .background(Color.background)
        .preferredColorScheme(.dark)
    }
}
#endif 