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
    @State private var selectedPreset: PresetHabit? = nil
    
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
                    Text(showingPresets ? "Choose Habit" : "Custom Habit")
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
                    }
                }
            }
        }
    }
    
    private var presetSection: some View {
        VStack(spacing: 20) {
            ForEach(presetHabits[selectedHabitType] ?? [], id: \.name) { preset in
                Button {
                    selectedPreset = preset
                    showingPresets = false
                } label: {
                    HStack {
                        Image(systemName: preset.iconName)
                            .font(.title2)
                            .foregroundColor(DesignTokens.Colors.electricBlue)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(preset.goalDescription ?? "")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            
            Button {
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
    
    private var customHabitForm: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Habit Name")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Enter habit name", text: $customHabitName)
                    .textFieldStyle(MinimalistTextFieldStyle())
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
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Goal")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack {
                    TextField("Target", value: $goalTarget, format: .number)
                        .textFieldStyle(MinimalistTextFieldStyle())
                        .frame(width: 100)
                    
                    Picker("Unit", selection: $goalUnit) {
                        ForEach(GoalUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Tracking Mode")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Picker("Tracking Mode", selection: $trackingMode) {
                    ForEach(TrackingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private func saveHabit() {
        if let preset = selectedPreset {
            habitService.addPresetHabit(preset)
        } else {
            habitService.addHabit(
                name: customHabitName,
                type: selectedHabitType,
                iconName: selectedIcon,
                isCustom: true,
                goalTarget: goalTarget,
                goalUnit: goalUnit,
                goalDescription: goalDescription.isEmpty ? nil : goalDescription,
                trackingMode: trackingMode
            )
        }
        dismiss()
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