import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var habitService: HabitService
    @EnvironmentObject private var dateManager: DateManager
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var showingDeleteConfirmation = false
    @State private var showDebugControls = false // Toggle for debug UI
    
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
        }
        .navigationBarHidden(true)
        .onAppear {
            print("📱 DashboardView appeared")
            habitService.loadHabits()
        }
        .alert("Reset App?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                habitService.deleteAllHabits()
            }
        } message: {
            Text("This will permanently delete all habits and reset the app to a fresh state. This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func mainContent(habitService: HabitService) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header Section
                headerSection
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                
                // Stats Cards
                statsSection(habitService: habitService)
                    .padding(.bottom, 32)
                
                // Habits Section
                habitsSection(habitService: habitService)
                
                // Bottom padding for floating button
                Spacer()
                    .frame(height: 120)
            }
        }
        .overlay(
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingAddHabit = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blue.opacity(0.9),
                                                Color.purple.opacity(0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .scaleEffect(showingAddHabit ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingAddHabit)
                    .padding(.trailing, 20)
                    .padding(.bottom, 34)
                }
            }
        )
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
        .sheet(item: $selectedHabit, onDismiss: {
            print("🏠 Dashboard: Sheet dismissed for habit")
        }) { habit in
            HabitDetailView(habit: habit)
        }
    }

    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            // App Title and Subtitle
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WillPowr")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Build habits. Quit bad ones.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Debug Toggle - Small Eyeball
                    VStack(spacing: 4) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDebugControls.toggle()
                            }
                        }) {
                            Image(systemName: showDebugControls ? "eye.fill" : "eye")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 20, height: 20)
                        }
                        
                        // Debug Controls - Show when toggled
                        if showDebugControls {
                            HStack(spacing: 8) {
                                // Previous Day
                                Button(action: {
                                    dateManager.moveBackwardOneDay()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.caption2)
                                        .foregroundColor(.blue.opacity(0.8))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                
                                // Reset to Today
                                Button(action: {
                                    dateManager.resetToToday()
                                }) {
                                    Image(systemName: "house")
                                        .font(.caption2)
                                        .foregroundColor(.green.opacity(0.8))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                
                                // Next Day
                                Button(action: {
                                    dateManager.moveForwardOneDay()
                                }) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.blue.opacity(0.8))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                
                                // Debug trash button
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash.fill")
                                        .font(.caption2)
                                        .foregroundColor(.red.opacity(0.7))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                
                                // Health Data Fetch Button
                                Button(action: {
                                    Task {
                                        await healthKitService.fetchAllHealthData()
                                    }
                                }) {
                                    Image(systemName: "heart.text.square.fill")
                                        .font(.caption2)
                                        .foregroundColor(.pink.opacity(0.8))
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            
            // Date Display
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentDateString)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(dateManager.isDebugging ? .orange : .white)
                    
                    if dateManager.isDebugging {
                        Text("DEBUG MODE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    } else {
                        Text("Today")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if dateManager.isDebugging {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
            
            VStack(spacing: 8) {
                Text("Service Not Available")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Unable to load habit service. Please restart the app.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
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
    
    @ViewBuilder
    private func statsSection(habitService: HabitService) -> some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Habits",
                value: "\(habitService.totalActiveHabits())",
                icon: "target",
                color: .indigo
            )
            
            StatCard(
                title: "Completed Today",
                value: "\(habitService.habitsCompletedToday())",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func habitsSection(habitService: HabitService) -> some View {
        let sortedHabits = habitService.sortedHabits()
        
        if !sortedHabits.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Your Habits")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(sortedHabits.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
                .padding(.horizontal, 20)
                
                LazyVStack(spacing: 12) {
                    ForEach(sortedHabits) { habit in
                        HabitCard(habit: habit) {
                            print("🏠 Dashboard: Selected habit '\(habit.name)' for detail view")
                            selectedHabit = habit
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        } else {
            emptyStateView
        }
    }

    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                
                VStack(spacing: 8) {
                    Text("Start Your Journey")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Add your first habit and begin building the life you want.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Add Habit Button
    
    private var addHabitButton: some View {
        Button {
            showingAddHabit = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add New Habit")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Helper Methods
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: dateManager.currentDate)
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    private var currentDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM d"
        return dateFormatter.string(from: dateManager.currentDate)
    }
    
    private var currentDateWithDayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, yyyy"
        return dateFormatter.string(from: dateManager.currentDate)
    }
    
    private func refreshHabits() async {
        await Task { @MainActor in
            print("🔄 DashboardView: Refreshing habits")
            habitService.loadHabits()
        }.value
    }
}

// MARK: - Floating Orbs Background Component

struct FloatingOrbs: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Optimized Large orb - reduced blur and simplified gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .center,
                        endPoint: .trailing
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 8)
                .offset(
                    x: animate ? -40 : 40,
                    y: animate ? -60 : 60
                )
                .animation(
                    .linear(duration: 12)
                    .repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Optimized Medium orb
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .center,
                        endPoint: .trailing
                    )
                )
                .frame(width: 140, height: 140)
                .blur(radius: 6)
                .offset(
                    x: animate ? 60 : -60,
                    y: animate ? 80 : -80
                )
                .animation(
                    .linear(duration: 16)
                    .repeatForever(autoreverses: true),
                    value: animate
                )
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
} 