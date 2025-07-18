import SwiftUI

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.habitService) private var habitService
    
    @State private var selectedHabitType: HabitType = .build
    @State private var customHabitName = ""
    @State private var selectedIcon = "star.fill"
    @State private var showingPresets = true
    @State private var animateContent = false
    
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
                    addCustomHabit(habitService)
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
    
    private func addPresetHabit(_ preset: PresetHabit, habitService: HabitService) {
        print("🎯 Adding preset habit: \(preset.name)")
        habitService.addPresetHabit(preset)
        dismiss()
    }
    
    private func addCustomHabit(_ habitService: HabitService) {
        guard !customHabitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        print("🎯 AddHabitView: Adding custom habit - \(customHabitName)")
        habitService.addHabit(
            name: customHabitName,
            type: selectedHabitType,
            iconName: selectedIcon,
            isCustom: true
        )
        dismiss()
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