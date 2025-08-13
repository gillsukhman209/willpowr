import SwiftUI

struct MinimalistDashboardView: View {
    @EnvironmentObject private var habitService: HabitService
    @EnvironmentObject private var dateManager: DateManager
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var healthKitService: HealthKitService
    @EnvironmentObject private var autoSyncService: AutoSyncService
    @EnvironmentObject private var backgroundSyncService: BackgroundSyncService
    
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var scrollOffset: CGFloat = 0
    @State private var showMotivation = true
    @State private var showDebugPanel = false
    
    // Animation states
    @State private var titleOpacity: Double = 0
    @State private var contentOffset: CGFloat = 50
    @State private var morphingShapeOffset: CGFloat = -100
    
    var body: some View {
        ZStack {
            // Pure black background
            DesignTokens.Colors.pureBlack
                .ignoresSafeArea()
            
            // Morphing geometric background
            GeometryReader { geometry in
                MorphingShape(
                    color: DesignTokens.Colors.electricBlue.opacity(0.1),
                    size: geometry.size.width * 0.8
                )
                .position(
                    x: geometry.size.width * 0.85,
                    y: morphingShapeOffset + scrollOffset * 0.3
                )
                .allowsHitTesting(false)
            }
            
            // Main content
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Giant typography header
                        headerSection
                            .id("header")
                        
                        // Daily motivation (if enabled)
                        if showMotivation {
                            motivationSection
                                .padding(.vertical, DesignTokens.Spacing.giant)
                        }
                        
                        // Habits list with stagger animation
                        habitsSection
                            .padding(.top, DesignTokens.Spacing.xxlarge)
                        
                        // Bottom spacing
                        Spacer(minLength: 150)
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MinimalFloatingButton(action: {
                        showingAddHabit = true
                    })
                    .padding(.trailing, DesignTokens.Spacing.large)
                    .padding(.bottom, DesignTokens.Spacing.xlarge)
                }
            }
            
            // Debug Panel Overlay
            if showDebugPanel {
                VStack {
                    Spacer()
                    DebugHistoryPanel()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: -5)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .sheet(isPresented: $showingAddHabit) {
            MinimalistAddHabitView()
        }
        .sheet(item: $selectedHabit) { habit in
            MinimalistHabitDetailView(habit: habit)
        }
        .onAppear {
            animateIn()
            habitService.loadHabits()
            
            Task {
                await autoSyncService.syncAllHabits()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            // Date, sync status, and debug toggle
            HStack {
                Text(currentDateString.uppercased())
                    .micro()
                    .foregroundColor(DesignTokens.Colors.offWhite.opacity(0.5))
                    .tracking(DesignTokens.Typography.ultraWideSpacing)
                
                Spacer()
                
                HStack(spacing: 12) {
                    SyncStatusView()
                    
                    // Debug Panel Toggle
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDebugPanel.toggle()
                        }
                    }) {
                        Image(systemName: showDebugPanel ? "eye.fill" : "eye")
                            .font(.caption)
                            .foregroundColor(showDebugPanel ? .orange : .secondary)
                            .frame(width: 20, height: 20)
                    }
                    
                    // Smart Notification Test Button
                    Button(action: {
                        Task {
                            if !notificationService.hasPermission {
                                await notificationService.requestPermission()
                            } else {
                                notificationService.sendSmartTestNotification(for: habitService)
                            }
                        }
                    }) {
                        Image(systemName: "bell.badge.fill")
                            .font(.caption)
                            .foregroundColor(notificationService.hasPermission ? .blue : .gray)
                            .frame(width: 20, height: 20)
                    }
                    
                    // Delayed Notification Test Button
                    Button(action: {
                        notificationService.sendDelayedTestNotification(delay: 5)
                    }) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                    }
                    
                    // Smart Reminders Button
                    Button(action: {
                        notificationService.scheduleHabitReminders(for: habitService)
                    }) {
                        Image(systemName: "alarm.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            // Giant title
            Text("WILL\nPOWR")
                .giantTitle()
                .foregroundColor(DesignTokens.Colors.offWhite)
                .opacity(titleOpacity)
                .offset(y: contentOffset)
            
            // Stats row
            HStack(spacing: DesignTokens.Spacing.xxlarge) {
                StatBlock(
                    number: habitService.totalActiveHabits(),
                    label: "ACTIVE",
                    color: DesignTokens.Colors.electricBlue
                )
                
                StatBlock(
                    number: habitService.habitsCompletedToday(),
                    label: "DONE",
                    color: DesignTokens.Colors.neonGreen
                )
            }
            .padding(.top, DesignTokens.Spacing.large)
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .padding(.top, 100)
    }
    
    // MARK: - Motivation Section
    private var motivationSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(getMotivationalQuote())
                .font(.system(size: DesignTokens.Typography.title, weight: .ultraLight))
                .foregroundColor(DesignTokens.Colors.offWhite.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            Text("— DAILY WISDOM")
                .micro()
                .foregroundColor(DesignTokens.Colors.offWhite.opacity(0.3))
                .tracking(DesignTokens.Typography.ultraWideSpacing)
        }
        .padding(.horizontal, DesignTokens.Spacing.large)
        .opacity(titleOpacity)
    }
    
    // MARK: - Habits Section
    private var habitsSection: some View {
        VStack(spacing: 0) {
            if habitService.habits.isEmpty {
                emptyState
            } else {
                ForEach(Array(habitService.sortedHabits().enumerated()), id: \.element.id) { index, habit in
                    MinimalistHabitRow(
                        habit: habit,
                        index: index,
                        onTap: {
                            selectedHabit = habit
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom).combined(with: .opacity),
                        removal: .push(from: .top).combined(with: .opacity)
                    ))
                    
                    if index < habitService.habits.count - 1 {
                        Divider()
                            .background(DesignTokens.Colors.offWhite.opacity(0.1))
                            .padding(.horizontal, DesignTokens.Spacing.large)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            Text("NO HABITS YET")
                .headline()
                .foregroundColor(DesignTokens.Colors.offWhite.opacity(0.3))
                .tracking(DesignTokens.Typography.wideSpacing)
            
            Text("TAP + TO BEGIN")
                .caption()
                .foregroundColor(DesignTokens.Colors.offWhite.opacity(0.2))
                .tracking(DesignTokens.Typography.ultraWideSpacing)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.giant)
    }
    
    // MARK: - Helper Methods
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: dateManager.currentDate)
    }
    
    
    private func getMotivationalQuote() -> String {
        let quotes = [
            "The only way out is through.",
            "Discipline is choosing between what you want now and what you want most.",
            "You are what you repeatedly do.",
            "Small steps daily lead to big changes yearly.",
            "The pain of discipline weighs ounces, the pain of regret weighs tons.",
            "Success is the sum of small efforts repeated day in and day out.",
            "Don't count the days, make the days count."
        ]
        return quotes.randomElement() ?? quotes[0]
    }
    
    private func animateIn() {
        withAnimation(.easeOut(duration: 0.8)) {
            titleOpacity = 1
            contentOffset = 0
        }
        
        withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
            morphingShapeOffset = 100
        }
    }
}

// MARK: - Stat Block Component
struct StatBlock: View {
    let number: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.micro) {
            AnimatedCounter(
                value: number,
                fontSize: DesignTokens.Typography.largeTitle,
                color: color,
                duration: 0.8
            )
            
            Text(label)
                .micro()
                .foregroundColor(color.opacity(0.6))
                .tracking(DesignTokens.Typography.ultraWideSpacing)
        }
    }
}

// MARK: - Minimalist Habit Row
struct MinimalistHabitRow: View {
    let habit: Habit
    let index: Int
    let onTap: () -> Void
    
    @EnvironmentObject private var habitService: HabitService
    @State private var isVisible = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.large) {
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(DesignTokens.Colors.lightGray, lineWidth: 2)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: habit.progressPercentage)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(habit.progressPercentage * 100))")
                        .font(.system(size: DesignTokens.Typography.body, weight: .bold))
                        .foregroundColor(progressColor)
                }
                
                // Habit info
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.micro) {
                    Text(habit.name.uppercased())
                        .font(.system(size: DesignTokens.Typography.headline, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.offWhite)
                        .tracking(DesignTokens.Typography.normalSpacing)
                    
                    HStack(spacing: DesignTokens.Spacing.medium) {
                        // Streak
                        HStack(spacing: DesignTokens.Spacing.micro) {
                            if habit.streak > 7 {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignTokens.Colors.hotPink)
                            }
                            Text("\(habit.streak) DAYS")
                                .micro()
                                .foregroundColor(DesignTokens.Colors.offWhite.opacity(0.5))
                        }
                        
                        // Type indicator
                        Text(habit.habitType == .build ? "BUILD" : "QUIT")
                            .micro()
                            .foregroundColor(progressColor.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Action indicator - always show to indicate row is clickable
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.offWhite.opacity(0.3))
            }
            .padding(.horizontal, DesignTokens.Spacing.large)
            .padding(.vertical, DesignTokens.Spacing.large)
            .background(
                Rectangle()
                    .fill(isPressed ? DesignTokens.Colors.lightGray.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : -50)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.1)) {
                isVisible = true
            }
        }
    }
    
    private var progressColor: Color {
        if habit.isCompleted || habit.isGoalMet {
            return DesignTokens.Colors.neonGreen
        } else if habit.habitType == .build {
            return DesignTokens.Colors.electricBlue
        } else {
            return DesignTokens.Colors.hotPink
        }
    }
}

// MARK: - Minimal Floating Button
struct MinimalFloatingButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var rotation: Double = 0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.offWhite)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.pureBlack)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1)
        .shadow(
            color: DesignTokens.Colors.offWhite.opacity(0.3),
            radius: isPressed ? 10 : 20,
            x: 0,
            y: isPressed ? 5 : 10
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                        rotation += 90
                    }
                }
        )
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}