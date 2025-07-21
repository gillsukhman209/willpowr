import SwiftUI

struct MinimalistAddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var habitService: HabitService
    
    @State private var selectedHabitType: HabitType = .build
    @State private var customHabitName = ""
    @State private var selectedIcon = "star.fill"
    @State private var showingPresets = true
    
    @State private var goalTarget: Double = 1
    @State private var goalUnit: GoalUnit = .none
    @State private var goalDescription: String = ""
    @State private var trackingMode: TrackingMode = .manual
    @State private var quitHabitType: QuitHabitType = .abstinence
    @State private var selectedPreset: PresetHabit? = nil
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private var presetHabits: [HabitType: [PresetHabit]] {
        [
            .build: PresetHabit.buildHabits,
            .quit: PresetHabit.quitHabits
        ]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        if showingPresets {
                            presetSection
                        } else if selectedPreset != nil {
                            presetConfigurationForm
                        } else {
                            customHabitForm
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .principal) {
                    Text(getNavigationTitle())
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                if !showingPresets {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveHabit()
                        }
                        .foregroundColor(DesignTokens.Colors.electricBlue)
                        .fontWeight(.semibold)
                        .disabled(!canSaveHabit())
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(habitService.$error) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
                habitService.error = nil // Clear the error
            }
        }
    }
    
    private var presetSection: some View {
        VStack(spacing: 20) {
            // Habit Type Selector
            VStack(spacing: 12) {
                Text("What type of habit do you want to build?")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    ForEach(HabitType.allCases, id: \.self) { type in
                        Button {
                            selectedHabitType = type
                        } label: {
                            Text(type.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedHabitType == type ? .black : .white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    selectedHabitType == type ?
                                    DesignTokens.Colors.electricBlue :
                                    Color.white.opacity(0.1)
                                )
                                .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(.bottom, 10)
            
            ForEach(presetHabits[selectedHabitType] ?? [], id: \.name) { preset in
                let isAlreadyAdded = habitService.habitExists(name: preset.name)
                
                Button {
                    if isAlreadyAdded {
                        showDuplicateError(for: preset.name)
                    } else {
                        selectedPreset = preset
                        goalTarget = preset.defaultGoalTarget
                        goalUnit = preset.defaultGoalUnit
                        goalDescription = preset.goalDescription ?? ""
                        trackingMode = preset.defaultTrackingMode
                        quitHabitType = preset.defaultQuitHabitType
                        showingPresets = false
                    }
                } label: {
                    HStack {
                        Image(systemName: preset.iconName)
                            .font(.title2)
                            .foregroundColor(
                                isAlreadyAdded ? .gray : DesignTokens.Colors.electricBlue
                            )
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(isAlreadyAdded ? .gray : .white)
                                
                                if isAlreadyAdded {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(DesignTokens.Colors.neonGreen)
                                }
                            }
                            
                            Text(isAlreadyAdded ? "Already added" : (preset.goalDescription ?? ""))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: isAlreadyAdded ? "checkmark.circle.fill" : "chevron.right")
                            .foregroundColor(
                                isAlreadyAdded ? DesignTokens.Colors.neonGreen : .white.opacity(0.3)
                            )
                    }
                    .padding()
                    .background(
                        isAlreadyAdded ? 
                        Color.white.opacity(0.02) : 
                        Color.white.opacity(0.05)
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isAlreadyAdded ? DesignTokens.Colors.neonGreen.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .disabled(isAlreadyAdded)
            }
            
            Button {
                selectedPreset = nil
                showingPresets = false
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.neonGreen)
                    
                    Text("Create Custom Habit")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }
    
    private var presetConfigurationForm: some View {
        VStack(spacing: 25) {
            if let preset = selectedPreset {
                presetHeader(preset)
                presetGoalConfiguration
                presetBackButton
            }
        }
    }
    
    private func presetHeader(_ preset: PresetHabit) -> some View {
        VStack(spacing: 15) {
            Image(systemName: preset.iconName)
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.electricBlue)
                .padding()
                .background(
                    Circle()
                        .fill(DesignTokens.Colors.electricBlue.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(DesignTokens.Colors.electricBlue.opacity(0.3), lineWidth: 1)
                        )
                )
            
            Text(preset.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let description = preset.goalDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 10)
    }
    
    private var presetGoalConfiguration: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let preset = selectedPreset, preset.habitType == .quit && quitHabitType == .abstinence {
                // Abstinence habits - no goal configuration needed
                abstinenceHabitExplanation
            } else {
                // Limit habits and build habits - show goal configuration
                goalConfigurationSection
            }
        }
    }
    
    private var abstinenceHabitExplanation: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Complete Abstinence")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                    
                    Text("Goal: Zero Usage")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Text("This habit focuses on completely avoiding the behavior. No daily limits or targets - the goal is total abstinence.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var goalConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(quitHabitType == .limit ? "Daily Limit Configuration" : "Goal Configuration")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(quitHabitType == .limit ? "Daily Limit" : "Target")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 15) {
                    TextField("Target", value: $goalTarget, format: .number)
                        .textFieldStyle(MinimalistTextFieldStyle())
                        .frame(width: 100)
                    
                    Text(goalUnit.longDisplayName)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            if goalUnit.supportsAutoTracking {
                presetTrackingModeSelection
            }
        }
    }
    
    private var presetTrackingModeSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tracking Mode")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                ForEach(TrackingMode.allCases, id: \.self) { mode in
                    presetTrackingModeButton(mode)
                }
            }
        }
    }
    
    private func presetTrackingModeButton(_ mode: TrackingMode) -> some View {
        Button {
            trackingMode = mode
        } label: {
            HStack {
                Image(systemName: mode.iconName)
                    .foregroundColor(trackingMode == mode ? .white : .white.opacity(0.6))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(trackingMode == mode ? .white : .white.opacity(0.6))
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if trackingMode == mode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.electricBlue)
                }
            }
            .padding()
            .background(
                Color.white.opacity(trackingMode == mode ? 0.1 : 0.05)
            )
            .cornerRadius(12)
        }
    }
    
    private var presetBackButton: some View {
        Button {
            showingPresets = true
            selectedPreset = nil
        } label: {
            Text("← Choose Different Habit")
                .font(.subheadline)
                .foregroundColor(DesignTokens.Colors.electricBlue)
                .padding()
        }
    }
    
    private var customHabitForm: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Habit Name")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Enter habit name", text: $customHabitName)
                        .textFieldStyle(MinimalistTextFieldStyle())
                    
                    if !customHabitName.isEmpty && habitService.habitExists(name: customHabitName.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("This habit name is already taken")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Icon")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(habitIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .black : .white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        selectedIcon == icon ?
                                        DesignTokens.Colors.electricBlue :
                                        Color.white.opacity(0.1)
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            
            if selectedHabitType == .quit {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quit Approach")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        ForEach(QuitHabitType.allCases, id: \.self) { type in
                            Button {
                                quitHabitType = type
                            } label: {
                                HStack {
                                    Image(systemName: type.iconName)
                                        .foregroundColor(quitHabitType == type ? .white : .white.opacity(0.6))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(type.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(quitHabitType == type ? .white : .white.opacity(0.6))
                                        
                                        Text(type.description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    if quitHabitType == type {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(DesignTokens.Colors.electricBlue)
                                    }
                                }
                                .padding()
                                .background(
                                    Color.white.opacity(quitHabitType == type ? 0.1 : 0.05)
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            
            if selectedHabitType == .build || (selectedHabitType == .quit && quitHabitType == .limit) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedHabitType == .quit && quitHabitType == .limit ? "Daily Limit" : "Goal")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(spacing: 10) {
                    HStack(spacing: 15) {
                        TextField("Target", value: $goalTarget, format: .number)
                            .textFieldStyle(MinimalistTextFieldStyle())
                            .frame(width: 100)
                        
                        Text(goalUnit.longDisplayName)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Goal Unit Selection
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(GoalUnit.allCases, id: \.self) { unit in
                                Button {
                                    goalUnit = unit
                                } label: {
                                    Text(unit == .none ? "Complete/Incomplete" : unit.longDisplayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(goalUnit == unit ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            goalUnit == unit ?
                                            DesignTokens.Colors.electricBlue :
                                            Color.white.opacity(0.1)
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                }
            }
            
            if goalUnit.supportsAutoTracking && selectedHabitType == .build {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tracking Mode")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        ForEach(TrackingMode.allCases, id: \.self) { mode in
                            Button {
                                trackingMode = mode
                            } label: {
                                HStack {
                                    Image(systemName: mode.iconName)
                                        .foregroundColor(trackingMode == mode ? .white : .white.opacity(0.6))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(mode.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(trackingMode == mode ? .white : .white.opacity(0.6))
                                        
                                        Text(mode.description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    if trackingMode == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(DesignTokens.Colors.electricBlue)
                                    }
                                }
                                .padding()
                                .background(
                                    Color.white.opacity(trackingMode == mode ? 0.1 : 0.05)
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func showDuplicateError(for habitName: String) {
        errorMessage = "You already have a habit named '\(habitName)'"
        showingErrorAlert = true
    }
    
    private func saveHabit() {
        if let preset = selectedPreset {
            // Create habit with configured values, not preset defaults
            habitService.addHabit(
                name: preset.name,
                type: preset.habitType,
                iconName: preset.iconName,
                isCustom: false,
                goalTarget: goalTarget,
                goalUnit: goalUnit,
                goalDescription: goalDescription.isEmpty ? preset.goalDescription : goalDescription,
                trackingMode: trackingMode,
                quitHabitType: quitHabitType
            )
        } else {
            habitService.addHabit(
                name: customHabitName,
                type: selectedHabitType,
                iconName: selectedIcon,
                isCustom: true,
                goalTarget: goalTarget,
                goalUnit: goalUnit,
                goalDescription: goalDescription.isEmpty ? nil : goalDescription,
                trackingMode: trackingMode,
                quitHabitType: quitHabitType
            )
        }
        
        // Check if there was an error, if not, dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if habitService.error == nil {
                dismiss()
            }
        }
    }
    
    private func getNavigationTitle() -> String {
        if showingPresets {
            return "Choose Habit"
        } else if selectedPreset != nil {
            return "Configure Habit"
        } else {
            return "Custom Habit"
        }
    }
    
    private func canSaveHabit() -> Bool {
        if selectedPreset != nil {
            // For abstinence habits, goalTarget of 0 is valid
            if let preset = selectedPreset, preset.habitType == .quit && quitHabitType == .abstinence {
                return true
            }
            // For other habits, goalTarget must be > 0
            return goalTarget > 0
        } else {
            let trimmedName = customHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
            // For custom abstinence habits, goalTarget of 0 is valid
            if selectedHabitType == .quit && quitHabitType == .abstinence {
                return !trimmedName.isEmpty && !habitService.habitExists(name: trimmedName)
            }
            // For other custom habits, goalTarget must be > 0
            return !trimmedName.isEmpty && goalTarget > 0 && !habitService.habitExists(name: trimmedName)
        }
    }
}

struct MinimalistTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

let habitIcons = [
    "star.fill", "heart.fill", "bolt.fill", "flame.fill",
    "drop.fill", "leaf.fill", "moon.fill", "sun.max.fill",
    "book.fill", "pencil", "paintbrush.fill", "music.note",
    "sportscourt.fill", "figure.run", "bicycle", "dumbbell.fill"
]