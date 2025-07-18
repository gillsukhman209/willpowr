import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.habitService) private var habitService
    
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
                // Background
                Color.black
                    .ignoresSafeArea()
                
                if let habitService = habitService {
                    mainContent(habitService: habitService)
                } else {
                    errorContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
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
                    if let habitService = habitService {
                        if selectedPreset != nil {
                            finalizeHabit(habitService: habitService)
                        } else {
                            createCustomHabit(habitService: habitService)
                        }
                    }
                },
                onCancel: {
                    showingGoalSettings = false
                }
            )
        }
    }
    
    @ViewBuilder
    private func mainContent(habitService: HabitService) -> some View {
        ScrollView {
            LazyVStack(spacing: 24) {
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
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    @ViewBuilder
    private var errorContent: some View {
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
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
            
            VStack(spacing: 8) {
                Text("Add New Habit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Choose a habit to build or quit")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
        }
    }
    
    // MARK: - Habit Type Selection
    
    private var habitTypeSelection: some View {
        VStack(spacing: 16) {
            Text("What do you want to do?")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Build Habit Button
                habitTypeButton(
                    type: .build,
                    title: "Build Habit",
                    subtitle: "Create a positive habit",
                    icon: "plus.circle.fill",
                    color: .success
                )
                
                // Quit Habit Button
                habitTypeButton(
                    type: .quit,
                    title: "Quit Habit",
                    subtitle: "Stop a negative habit",
                    icon: "minus.circle.fill",
                    color: .failure
                )
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
    }
    
    // MARK: - Habit Type Button
    
    private func habitTypeButton(type: HabitType, title: String, subtitle: String, icon: String, color: Color) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedHabitType = type
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selectedHabitType == type ? color.opacity(0.1) : Color.fallbackGlassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedHabitType == type ? color : Color.fallbackGlassBorder, lineWidth: selectedHabitType == type ? 2 : 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Preset Habits Section
    
    private func presetHabitsSection(habitService: HabitService) -> some View {
        VStack(spacing: 16) {
            Text("Choose a preset habit")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            let presets = selectedHabitType == .build ? PresetHabit.buildHabits : PresetHabit.quitHabits
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            
            if presets.isEmpty {
                Text("No preset habits available for this type.")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(presets, id: \.name) { preset in
                        presetHabitCard(preset: preset, habitService: habitService)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                    }
                }
            }
        }
    }
    
    // MARK: - Preset Habit Card
    
    private func presetHabitCard(preset: PresetHabit, habitService: HabitService) -> some View {
        Button {
            addPresetHabit(preset, habitService: habitService)
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(habitTypeColor(for: preset.habitType))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: preset.iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Text(preset.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
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
        .buttonStyle(PressedButtonStyle())
    }
    
    // MARK: - Custom Habit Section
    
    private func customHabitSection(habitService: HabitService) -> some View {
        VStack(spacing: 20) {
            Text("Create custom habit")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Habit Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Habit Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
                    TextField("Enter habit name", text: $customHabitName)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Icon Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose Icon")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                    
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
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.headline)
                        Text("Add Habit")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(habitTypeColor(for: selectedHabitType))
                            .shadow(color: habitTypeColor(for: selectedHabitType).opacity(0.3), radius: 4, x: 0, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding(.horizontal, 4)
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
    }
    
    // MARK: - Icon Selection Grid
    
    private var iconSelectionGrid: some View {
        let icons = ["star.fill", "heart.fill", "flame.fill", "bolt.fill", "leaf.fill", "drop.fill", "brain.head.profile", "dumbbell.fill", "book.fill", "bed.double.fill", "fork.knife", "figure.walk"]
        
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(selectedIcon == icon ? .white : .gray)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(selectedIcon == icon ? habitTypeColor(for: selectedHabitType) : Color.fallbackGlassBackground)
                                .overlay(
                                    Circle()
                                        .stroke(Color.fallbackGlassBorder, lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
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
            HStack {
                Image(systemName: showingPresets ? "pencil.circle" : "grid.circle")
                    .font(.headline)
                Text(showingPresets ? "Create Custom" : "Choose Preset")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateContent ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateContent)
    }
    
    // MARK: - Helper Methods
    
    private func habitTypeColor(for type: HabitType) -> Color {
        switch type {
        case .build: return .success
        case .quit: return .failure
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
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Set Your Goal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Customize your \(habitName.lowercased()) target")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : -20)
                    .animation(.easeOut(duration: 0.6), value: animateContent)
                    
                    // Goal Settings
                    VStack(spacing: 20) {
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
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateContent)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Save Button
                        Button(action: onSave) {
                            Text("Save Habit")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.blue, .purple]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        
                        // Cancel Button
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateContent)
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            targetText = "\(Int(goalTarget))"
            withAnimation(.easeInOut(duration: 0.6)) {
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Measurement Unit")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if goalUnit == .none {
                // Show all options when no unit is selected
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(GoalUnit.allCases, id: \.self) { unit in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
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
                            VStack(spacing: 4) {
                                Text(unit.longDisplayName.isEmpty ? "Simple" : unit.longDisplayName.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(unit.displayName.isEmpty ? "✓" : unit.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            } else {
                // Show selected unit with change button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Unit")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(goalUnit.longDisplayName.isEmpty ? "Simple Completion" : goalUnit.longDisplayName.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            goalUnit = .none
                        }
                    } label: {
                        Text("Change")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.blue.opacity(0.1))
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private var targetInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Amount")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                TextField("Enter target", text: $targetText)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                
                Text(goalUnit.displayName)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var descriptionInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Description (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            TextField("e.g., Walk 8,000 steps daily", text: $goalDescription)
                .font(.body)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Custom Button Style

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.fallbackGlassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.fallbackGlassBorder, lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Preview

#Preview {
    AddHabitView()
        .preferredColorScheme(.dark)
} 