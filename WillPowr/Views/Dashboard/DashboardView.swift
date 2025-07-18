import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                content(for: geometry)
            }
            .navigationTitle("WillPowr")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $viewModel.showingAddHabit) {
                AddHabitView { habit in
                    viewModel.addHabit(habit)
                    viewModel.hideAddHabit()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An error occurred")
            }
        }
        .refreshable {
            viewModel.refreshHabits()
        }
    }
    
    // MARK: - Content
    @ViewBuilder
    private func content(for geometry: GeometryProxy) -> some View {
        if viewModel.isLoading {
            LoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.hasHabits {
            emptyState
        } else {
            habitsContent(for: geometry)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        EmptyStateView(
            title: "Start Building Better Habits",
            message: "Create your first habit to begin your journey towards a better you. Choose to build good habits or quit bad ones.",
            systemImage: "target"
        ) {
            viewModel.showAddHabit()
        }
    }
    
    // MARK: - Habits Content
    @ViewBuilder
    private func habitsContent(for geometry: GeometryProxy) -> some View {
        if geometry.size.width > 768 {
            // iPad or large screen layout
            regularSizeContent
        } else {
            // iPhone layout
            compactSizeContent
        }
    }
    
    // MARK: - Regular Size Content (iPad)
    private var regularSizeContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Header Section
                headerSection
                
                // Habits Grid
                habitsGrid
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xxl)
        }
    }
    
    // MARK: - Compact Size Content (iPhone)
    private var compactSizeContent: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Header Section
                headerSection
                
                // Habits List
                habitsList
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Spacing.md) {
            // Statistics Cards
            statisticsSection
            
            // Section Headers
            if viewModel.hasHabits {
                sectionHeaders
            }
        }
        .padding(.top, Spacing.lg)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        HStack(spacing: Spacing.md) {
            // Total Habits
            StatisticCard(
                title: "Active Habits",
                value: "\(viewModel.totalActiveHabits)",
                icon: "target",
                color: .primary
            )
            
            // Total Streak Days
            StatisticCard(
                title: "Total Streak",
                value: "\(viewModel.totalStreakDays)",
                icon: "flame.fill",
                color: .buildHabit
            )
        }
    }
    
    // MARK: - Section Headers
    private var sectionHeaders: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !viewModel.buildHabits.isEmpty {
                HStack {
                    Label("Build Habits", systemImage: "arrow.up.circle.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.buildHabit)
                    
                    Spacer()
                    
                    Text("\(viewModel.buildHabits.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.tertiaryBackground)
                        )
                }
            }
            
            if !viewModel.quitHabits.isEmpty {
                HStack {
                    Label("Quit Habits", systemImage: "xmark.circle.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.quitHabit)
                    
                    Spacer()
                    
                    Text("\(viewModel.quitHabits.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .fill(Color.tertiaryBackground)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Habits Grid (iPad)
    private var habitsGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 2),
            spacing: Spacing.md
        ) {
            ForEach(viewModel.habits) { habit in
                HabitCardView(
                    habit: habit,
                    onComplete: {
                        viewModel.completeHabit(habit)
                    },
                    onFail: habit.type == .quit ? {
                        viewModel.failHabit(habit)
                    } : nil,
                    onTap: {
                        viewModel.selectHabit(habit)
                    }
                )
                .contextMenu {
                    contextMenu(for: habit)
                }
            }
        }
    }
    
    // MARK: - Habits List (iPhone)
    private var habitsList: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(viewModel.habits) { habit in
                HabitCardView(
                    habit: habit,
                    onComplete: {
                        viewModel.completeHabit(habit)
                    },
                    onFail: habit.type == .quit ? {
                        viewModel.failHabit(habit)
                    } : nil,
                    onTap: {
                        viewModel.selectHabit(habit)
                    }
                )
                .contextMenu {
                    contextMenu(for: habit)
                }
            }
        }
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenu(for habit: HabitModel) -> some View {
        Button(action: {
            viewModel.selectHabit(habit)
        }) {
            Label("View Details", systemImage: "info.circle")
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            viewModel.deleteHabit(habit)
        }) {
            Label("Delete Habit", systemImage: "trash")
        }
    }
    
    // MARK: - Add Button
    private var addButton: some View {
        Button(action: {
            viewModel.showAddHabit()
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Add new habit")
    }
}

// MARK: - Statistic Card
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .glassCard(cornerRadius: CornerRadius.md, shadowStyle: ShadowStyle.soft)
    }
}

// MARK: - Add Habit View
struct AddHabitView: View {
    @StateObject private var viewModel = AddHabitViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let onHabitCreated: (HabitModel) -> Void
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Add Habit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "An error occurred")
        }
    }
    
    // MARK: - Content
    private var content: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Habit Type Selection
                habitTypeSelection
                
                // Preset Habits
                presetHabitsSection
                
                // Custom Habit Button
                customHabitButton
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }
        .sheet(isPresented: $viewModel.showingCustomHabit) {
            CustomHabitView(
                selectedType: viewModel.selectedType,
                onHabitCreated: { habit in
                    onHabitCreated(habit)
                    viewModel.hideCustomHabit()
                }
            )
        }
    }
    
    // MARK: - Habit Type Selection
    private var habitTypeSelection: some View {
        VStack(spacing: Spacing.md) {
            Text("What type of habit?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: Spacing.md) {
                ForEach(HabitType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.selectHabitType(type)
                    }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: type.systemImageName)
                                .font(.title3)
                            
                            Text(type.displayName)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(HabitTypeButtonStyle(
                        habitType: type,
                        isSelected: viewModel.selectedType == type
                    ))
                }
            }
        }
        .padding(.top, Spacing.lg)
    }
    
    // MARK: - Preset Habits Section
    private var presetHabitsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Choose a preset habit")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: horizontalSizeClass == .regular ? 3 : 2),
                spacing: Spacing.md
            ) {
                ForEach(viewModel.presetHabits) { habit in
                    PresetHabitCard(habit: habit) {
                        Task {
                            do {
                                let createdHabit = try await viewModel.createPresetHabit(habit)
                                onHabitCreated(createdHabit)
                            } catch {
                                // Error is handled by the view model
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Habit Button
    private var customHabitButton: some View {
        Button(action: {
            viewModel.showCustomHabit()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Create Custom Habit")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .buttonStyle(GradientButtonStyle(
            colors: [.primary, .primaryLight],
            cornerRadius: CornerRadius.lg
        ))
    }
}

// MARK: - Preset Habit Card
struct PresetHabitCard: View {
    let habit: HabitModel
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Spacing.md) {
                Image(systemName: habit.systemImageName)
                    .font(.title)
                    .foregroundColor(habit.type == .build ? .buildHabit : .quitHabit)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(
                                (habit.type == .build ? Color.buildHabit : Color.quitHabit)
                                    .opacity(0.1)
                            )
                    )
                
                Text(habit.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity)
            .glassCard(cornerRadius: CornerRadius.md, shadowStyle: ShadowStyle.soft)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            perform: {},
            onPressingChanged: { pressing in
                isPressed = pressing
            }
        )
    }
}

// MARK: - Custom Habit View
struct CustomHabitView: View {
    @StateObject private var viewModel = AddHabitViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let selectedType: HabitType
    let onHabitCreated: (HabitModel) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Habit Details")) {
                    TextField("Habit Name", text: $viewModel.habitName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 6),
                        spacing: Spacing.md
                    ) {
                        ForEach(iconOptions, id: \.self) { iconName in
                            Button(action: {
                                viewModel.selectedSystemImage = iconName
                            }) {
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(viewModel.selectedSystemImage == iconName ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                                            .fill(
                                                viewModel.selectedSystemImage == iconName ? 
                                                .primary : Color.tertiaryBackground
                                            )
                                    )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Custom Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            do {
                                let habit = try await viewModel.createHabit()
                                onHabitCreated(habit)
                                dismiss()
                            } catch {
                                // Error is handled by the view model
                            }
                        }
                    }
                    .disabled(!viewModel.canCreateHabit || viewModel.isCreating)
                }
            }
        }
        .onAppear {
            viewModel.selectHabitType(selectedType)
        }
    }
    
    private var iconOptions: [String] {
        [
            "star.fill", "heart.fill", "leaf.fill", "flame.fill",
            "target", "flag.fill", "bell.fill", "book.fill",
            "music.note", "gamecontroller.fill", "car.fill", "bicycle",
            "figure.walk", "dumbbell.fill", "drop.fill", "moon.fill"
        ]
    }
}

// MARK: - Preview Provider
#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DashboardView()
                .preferredColorScheme(.light)
            
            DashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif 