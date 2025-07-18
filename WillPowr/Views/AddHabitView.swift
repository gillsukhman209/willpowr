import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var habitService: HabitService
    
    @State private var selectedHabitType: HabitType = .build
    @State private var customHabitName = ""
    @State private var selectedIcon = "star.fill"
    @State private var showingPresets = true
    @State private var animateContent = false
    
    // Goal Setting State
    @State private var goalTarget: Double = 1
    @State private var goalUnit: GoalUnit = .none
    @State private var goalDescription: String = ""
    @State private var showingGoalSettings = false
    @State private var selectedPreset: PresetHabit? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background with Gradient
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
                
                // Floating orbs for depth
                FloatingOrbs()
                
                mainContent(habitService: habitService)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showingGoalSettings) {
            GoalSettingsView(
                habitName: selectedPreset?.name ?? customHabitName,
                goalTarget: $goalTarget,
                goalUnit: $goalUnit,
                goalDescription: $goalDescription,
                onSave: {
                    if selectedPreset != nil {
                        finalizeHabit(habitService: habitService)
                    } else {
                        createCustomHabit(habitService: habitService)
                    }
                },
                onCancel: {
                    showingGoalSettings = false
                }
            )
        }
        .dismissKeyboardOnTap()
    }
    
    @ViewBuilder
    private func mainContent(habitService: HabitService) -> some View {
        ScrollView {
            LazyVStack(spacing: 40) {
                // Header
                headerSection
                
                // Habit Type Selection
                habitTypeSelection
                
                // Content
                if showingPresets {
                    presetHabitsSection(habitService: habitService)
                } else {
                    customHabitSection(habitService: habitService)
                }
                
                // Toggle Button
                toggleButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40) // Extra bottom padding for safe area
        }
    }
    
    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Service Not Available")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Unable to load habit service. Please restart the app.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon with floating animation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.3),
                                Color.purple.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Image(systemName: "target")
                    .font(.system(size: 32))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple.opacity(0.8), .purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
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
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.5)
            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: animateContent)
            
            VStack(spacing: 8) {
                Text("Add New Habit")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Choose a habit to build or quit")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.2), value: animateContent)
        }
    }
    
    // MARK: - Habit Type Selection
    
    private var habitTypeSelection: some View {
        VStack(spacing: 20) {
            Text("What do you want to do?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Build Habit Button
                habitTypeButton(
                    type: .build,
                    title: "Build Habit",
                    subtitle: "Create a positive habit",
                    icon: "plus.circle.fill",
                    color: .green
                )
                
                // Quit Habit Button
                habitTypeButton(
                    type: .quit,
                    title: "Quit Habit",
                    subtitle: "Stop a negative habit",
                    icon: "minus.circle.fill",
                    color: .red
                )
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.3), value: animateContent)
    }
    
    // MARK: - Habit Type Button
    
    private func habitTypeButton(type: HabitType, title: String, subtitle: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedHabitType = type
            }
        } label: {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        selectedHabitType == type ? color.opacity(0.6) : .white.opacity(0.2),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: selectedHabitType == type ? 2 : 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            .scaleEffect(selectedHabitType == type ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedHabitType)
    }
    
    // MARK: - Preset Habits Section
    
    private func presetHabitsSection(habitService: HabitService) -> some View {
        VStack(spacing: 24) {
            Text("Choose a preset habit")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            let presets = selectedHabitType == .build ? PresetHabit.buildHabits : PresetHabit.quitHabits
            
            if presets.isEmpty {
                Text("No preset habits available for this type.")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 40)
            } else {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 2)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Array(presets.enumerated()), id: \.element.name) { index, preset in
                        presetHabitCard(preset: preset, habitService: habitService)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.4 + Double(index) * 0.1), value: animateContent)
                    }
                }
                .padding(.horizontal, 4) // Extra padding to prevent edge cutoff
            }
        }
    }
    
    // MARK: - Preset Habit Card
    
    private func presetHabitCard(preset: PresetHabit, habitService: HabitService) -> some View {
        Button {
            addPresetHabit(preset, habitService: habitService)
        } label: {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [habitTypeColor(for: preset.habitType).opacity(0.8), habitTypeColor(for: preset.habitType).opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: preset.iconName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .shadow(color: habitTypeColor(for: preset.habitType).opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
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
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Custom Habit Section
    
    private func customHabitSection(habitService: HabitService) -> some View {
        VStack(spacing: 24) {
            Text("Create custom habit")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                // Habit Name Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Habit Name")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    TextField("Enter habit name", text: $customHabitName)
                        .textFieldStyle(PremiumTextFieldStyle())
                }
                
                // Icon Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose Icon")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    iconSelectionGrid
                }
                
                // Add Button
                Button {
                    guard !customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return
                    }
                    
                    // Set up goal settings for custom habit
                    selectedPreset = nil
                    goalTarget = 1
                    goalUnit = .none
                    goalDescription = ""
                    showingGoalSettings = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Add Habit")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [habitTypeColor(for: selectedHabitType).opacity(0.8), habitTypeColor(for: selectedHabitType).opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
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
                    .shadow(color: habitTypeColor(for: selectedHabitType).opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
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
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(0.4), value: animateContent)
    }
    
    // MARK: - Icon Selection Grid
    
    private var iconSelectionGrid: some View {
        let icons = ["star.fill", "heart.fill", "flame.fill", "bolt.fill", "leaf.fill", "drop.fill", "brain.head.profile", "dumbbell.fill", "book.fill", "bed.double.fill", "fork.knife", "figure.walk"]
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(
                                    selectedIcon == icon ? 
                                    LinearGradient(
                                        colors: [habitTypeColor(for: selectedHabitType).opacity(0.8), habitTypeColor(for: selectedHabitType).opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [.white.opacity(0.1), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Circle()
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
                        .shadow(color: selectedIcon == icon ? habitTypeColor(for: selectedHabitType).opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
                        .scaleEffect(selectedIcon == icon ? 1.05 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIcon)
            }
        }
    }
    
    // MARK: - Toggle Button
    
    private var toggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showingPresets.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showingPresets ? "pencil.circle.fill" : "grid.circle.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(showingPresets ? "Create Custom" : "Choose Preset")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
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
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateContent ? 1 : 0)
        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
    }
    
    // MARK: - Helper Methods
    
    private func habitTypeColor(for type: HabitType) -> Color {
        switch type {
        case .build: return .green
        case .quit: return .red
        }
    }
    
    // MARK: - Actions
    
    private func addPresetHabit(_ preset: PresetHabit, habitService: HabitService) {
        // Set up goal settings from preset
        selectedPreset = preset
        goalTarget = preset.defaultGoalTarget
        goalUnit = preset.defaultGoalUnit
        goalDescription = preset.goalDescription ?? ""
        
        // Show goal settings screen
        showingGoalSettings = true
    }
    
    private func createCustomHabit(habitService: HabitService) {
        guard !customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        habitService.addHabit(
            name: customHabitName,
            type: selectedHabitType,
            iconName: selectedIcon,
            isCustom: true,
            goalTarget: goalTarget,
            goalUnit: goalUnit,
            goalDescription: goalDescription.isEmpty ? nil : goalDescription
        )
        
        dismiss()
    }
    
    private func finalizeHabit(habitService: HabitService) {
        if let preset = selectedPreset {
            habitService.addHabit(
                name: preset.name,
                type: preset.habitType,
                iconName: preset.iconName,
                isCustom: false,
                goalTarget: goalTarget,
                goalUnit: goalUnit,
                goalDescription: goalDescription.isEmpty ? nil : goalDescription
            )
        }
        
        dismiss()
    }
}



// MARK: - Goal Settings View

struct GoalSettingsView: View {
    let habitName: String
    @Binding var goalTarget: Double
    @Binding var goalUnit: GoalUnit
    @Binding var goalDescription: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var targetText: String = ""
    @State private var animateContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
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
                
                // Floating orbs
                FloatingOrbs()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Set Your Goal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Customize your \(habitName.lowercased()) target")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.8), value: animateContent)
                    
                    // Goal Settings
                    VStack(spacing: 28) {
                        // Unit Selector
                        unitSelector
                        
                        // Target Input - show when unit is selected and not .none
                        if goalUnit != .none {
                            targetInput
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Description Input - always show
                        descriptionInput
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateContent)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Save Button
                        Button(action: onSave) {
                            Text("Save Habit")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [.green.opacity(0.8), .green.opacity(0.6)],
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
                                .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Cancel Button
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: animateContent)
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            targetText = "\(Int(goalTarget))"
            withAnimation(.easeInOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .onChange(of: targetText) { _, newValue in
            if let value = Double(newValue), value > 0 {
                goalTarget = value
            }
        }
    }
    
    // MARK: - View Components
    
    private var unitSelector: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Measurement Unit")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if goalUnit == .none {
                // Show all options when no unit is selected
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(GoalUnit.allCases, id: \.self) { unit in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                goalUnit = unit
                                if unit == .none {
                                    goalTarget = 1
                                    targetText = "1"
                                } else {
                                    // Set reasonable defaults for each unit
                                    switch unit {
                                    case .steps:
                                        goalTarget = 8000
                                        targetText = "8000"
                                    case .minutes:
                                        goalTarget = 30
                                        targetText = "30"
                                    case .hours:
                                        goalTarget = 2
                                        targetText = "2"
                                    case .liters:
                                        goalTarget = 2
                                        targetText = "2"
                                    case .glasses:
                                        goalTarget = 8
                                        targetText = "8"
                                    case .grams:
                                        goalTarget = 25
                                        targetText = "25"
                                    case .count:
                                        goalTarget = 3
                                        targetText = "3"
                                    case .none:
                                        goalTarget = 1
                                        targetText = "1"
                                    }
                                }
                            }
                        } label: {
                            VStack(spacing: 10) {
                                Text(unit.longDisplayName.isEmpty ? "Simple" : unit.longDisplayName.capitalized)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text(unit.displayName.isEmpty ? "✓" : unit.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
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
                            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // Show selected unit with change button
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected Unit")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(goalUnit.longDisplayName.isEmpty ? "Simple Completion" : goalUnit.longDisplayName.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            goalUnit = .none
                        }
                    } label: {
                        Text("Change")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.gray.opacity(0.8), .gray.opacity(0.6)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
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
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
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
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
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
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var targetInput: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Target Amount")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack {
                TextField("Enter target", text: $targetText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                
                Text(goalUnit.displayName)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
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
            .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
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
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var descriptionInput: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Goal Description (Optional)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            TextField("e.g., Walk 8,000 steps daily", text: $goalDescription)
                .font(.subheadline)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
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
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
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
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    AddHabitView()
        .preferredColorScheme(.dark)
} 