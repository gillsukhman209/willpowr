import SwiftUI

struct HabitCard: View {
    let habit: Habit
    let onTap: () -> Void
    
    @EnvironmentObject private var habitService: HabitService
    @EnvironmentObject private var dateManager: DateManager
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var isPressed = false
    @State private var showingSuccess = false
    @State private var showingFail = false
    
    var body: some View {
        ZStack {
            // Modern gradient background
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.15, blue: 0.25),
                            Color(red: 0.05, green: 0.1, blue: 0.2),
                            Color(red: 0.08, green: 0.12, blue: 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: 24))
                .onTapGesture {
                    print("🎯 Card tapped for habit: \(habit.name)")
                    onTap()
                }
            
            // Content
            VStack(alignment: .leading, spacing: 24) {
                // Header with icon and streak
                modernHeader
                
                // Large progress display
                progressDisplay
                
                // Progress bar
                progressBar
                
                // Bottom stats
                bottomStats
                
                // Action buttons (only if needed)
                if shouldShowActionButtons {
                    actionButtons
                }
            }
            .padding(20)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Modern Header Section
    
    private var modernHeader: some View {
        HStack {
            // Icon and habit name
            HStack(spacing: 12) {
                Image(systemName: habit.iconName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text(habit.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Streak badge
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("\(habit.streak) day streak")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.15))
            )
        }
    }
    
    // MARK: - Progress Display
    
    private var progressDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Large progress numbers with tracking indicator
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(progressDisplayText)
                    .font(.system(size: progressFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(habit.trackingMode == .automatic ? Color.blue : Color.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                if !habit.goalUnit.displayName.isEmpty {
                    HStack(spacing: 4) {
                        Text(habit.goalUnit.displayName)
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        // Tracking mode indicator
                        if habit.trackingMode == .automatic {
                            Image(systemName: "waveform.path.ecg")
                                .font(.caption2)
                                .foregroundColor(.blue.opacity(0.6))
                        } else if habit.trackingMode == .manual && habit.goalUnit != .none {
                            Image(systemName: "hand.tap")
                                .font(.caption2)
                                .foregroundColor(.orange.opacity(0.6))
                        }
                    }
                }
            }
            

        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: habit.trackingMode == .automatic ? 
                                    [Color.blue, Color.blue.opacity(0.8)] :
                                    [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                }
            }
            .frame(height: 8)
            
            // Progress details
            HStack {
                Text(progressPercentage >= 1.0 ? "Goal Complete!" : "\(Int(progressPercentage * 100))% Complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(progressPercentage >= 1.0 ? .green : .gray)
                
                Spacer()
                
                if let timeToGoal = timeToGoalText {
                    Text(timeToGoal)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(habit.trackingMode == .automatic ? Color.blue : Color.orange)
                }
            }
        }
    }
    
    // MARK: - Bottom Stats
    
    private var bottomStats: some View {
        HStack {
            // Days completed
            VStack(alignment: .leading, spacing: 4) {
                Text("\(habit.streak)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(habit.trackingMode == .automatic ? Color.blue : Color.orange)
                
                Text("DAYS COMPLETED")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1, height: 40)
            
            Spacer()
            
            // Days remaining or goal info
            VStack(alignment: .trailing, spacing: 4) {
                Text(habit.goalTarget > 0 ? "\(Int(habit.goalTarget - habit.currentProgress))" : "∞")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(habit.trackingMode == .automatic ? Color.blue : Color.orange)
                
                Text(habit.goalTarget > 0 ? "REMAINING" : "DAILY GOAL")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 8)
    }
    

    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if habit.habitType == .build {
                if habit.trackingMode == .automatic {
                    if !healthKitService.isAuthorized {
                        // HealthKit not authorized - show manual fallback
                        modernActionButton(
                            title: "Complete (No HealthKit)",
                            icon: "hand.tap.fill",
                            color: .orange,
                            action: completeHabit
                        )
                    }
                    // If HealthKit is authorized, no button needed - auto-tracking handles it
                } else if !habit.isGoalMet {
                    // For manual habits, show regular complete button
                    modernActionButton(
                        title: "Complete",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        action: completeHabit
                    )
                }
            } else { // quit habit
                modernActionButton(
                    title: "Stay Strong",
                    icon: "checkmark.circle.fill", 
                    color: .green,
                    action: markQuitHabitSuccess
                )
                
                modernActionButton(
                    title: "I Failed",
                    icon: "xmark.circle.fill",
                    color: .red,
                    action: failHabit
                )
            }
        }
        .padding(.top, 8)
    }
    
    private func modernActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.9), color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Properties
    
    private var progressDisplayText: String {
        if habit.goalTarget > 0 {
            return "\(Int(habit.currentProgress))/\(Int(habit.goalTarget))"
        } else {
            return "\(Int(habit.currentProgress))"
        }
    }
    
    private var progressFontSize: CGFloat {
        let text = progressDisplayText
        let textLength = text.count
        
        // Adjust font size based on text length to ensure it fits on one line
        switch textLength {
        case 0...6:
            return 48 // "100/200" = 7 chars
        case 7...9:
            return 40 // "1000/2000" = 9 chars  
        case 10...12:
            return 36 // "10000/20000" = 11 chars
        case 13...15:
            return 32 // "100000/200000" = 13 chars
        default:
            return 28 // Really long numbers
        }
    }
    
    private var progressPercentage: Double {
        guard habit.goalTarget > 0 else { return 0 }
        return min(habit.currentProgress / habit.goalTarget, 1.0)
    }
    
    private var timeToGoalText: String? {
        guard habit.goalTarget > 0, habit.currentProgress < habit.goalTarget else { return nil }
        let remaining = habit.goalTarget - habit.currentProgress
        
        // Simple time estimate (this could be made more sophisticated)
        switch habit.goalUnit {
        case .steps:
            let minutes = Int(remaining / 100) // rough estimate: 100 steps per minute
            return "~\(minutes)m to goal"
        case .minutes:
            return "~\(Int(remaining))m to goal"
        case .hours:
            return "~\(Int(remaining))h to goal"
        default:
            return "~\(Int(remaining)) to goal"
        }
    }
    
    private var shouldShowActionButtons: Bool {
        // Always show buttons for quit habits
        if habit.habitType == .quit {
            return true
        }
        
        // For build habits with automatic tracking:
        // Only show fallback button if HealthKit not authorized
        if habit.trackingMode == .automatic {
            return !healthKitService.isAuthorized
        }
        
        // For manual tracking, show if not completed
        return !habit.isCompleted
    }
    
    // MARK: - Legacy Header Section (keeping for compatibility)
    
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
        VStack(spacing: 12) {
            if habit.habitType == .quit {
                // Quit habits need both success and failure buttons
                // Success button
                Button {
                    markQuitHabitSuccess()
                } label: {
                    HStack {
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(habit.isCompleted ? "Succeeded Today" : "I Succeeded Today")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: habit.isCompleted ? 
                                        [.green.opacity(1.0), .green.opacity(0.8)] :
                                        [.green.opacity(0.8), .green.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(habit.isCompleted)
                .opacity(habit.isCompleted ? 0.8 : 1.0)
                
                // Failure button
                Button {
                    failHabit()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("I Failed")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.8), .red.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
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
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(habit.isCompleted)
                .opacity(habit.isCompleted ? 0.5 : 1.0)
            } else {
                // Build habits - single button
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
            }
        }
        .overlay(
            ZStack {
            successOverlay
                failOverlay
            }
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
    
    // MARK: - Fail Overlay
    
    private var failOverlay: some View {
        ZStack {
            if showingFail {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.red.opacity(0.9), .red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Streak reset")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                    )
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showingFail)
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
    
    private func completeHabit() {
        if !habit.isGoalMet {
                            habitService.completeHabit(habit)
            showSuccessAnimation()
        }
    }
    
    private func failHabit() {
        habitService.failHabit(habit)
        showFailAnimation()
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
    
    private func showFailAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showingFail = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingFail = false
            }
        }
    }
    
    private func markQuitHabitSuccess() {
        habitService.markQuitHabitSuccess(habit)
        showSuccessAnimation()
    }
    
    private func handleAction() {
        if habit.habitType == .build {
            if !habit.isGoalMet {
                completeHabit()
            }
        } else {
            // This shouldn't be called for quit habits anymore since we have separate buttons
            failHabit()
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