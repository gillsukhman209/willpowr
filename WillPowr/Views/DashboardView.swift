import SwiftUI

struct DashboardView: View {
    @Environment(\.habitService) private var habitService
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var showingHabitDetail = false
    @State private var showingDeleteConfirmation = false
    
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
                
                if let habitService = habitService {
                    mainContent(habitService: habitService)
                } else {
                    errorContent
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("📱 DashboardView appeared")
            habitService?.loadHabits()
        }
        .alert("Reset App?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                habitService?.deleteAllHabits()
            }
        } message: {
            Text("This will permanently delete all habits and reset the app to a fresh state. This action cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func mainContent(habitService: HabitService) -> some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("WillPowr")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Build habits. Quit bad ones.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // Debug trash button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .scaleEffect(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                // Stats Cards
                statsSection(habitService: habitService)
                
                // Habits Section
                habitsSection(habitService: habitService)
                
                Spacer(minLength: 120)
            }
            .padding(.top, 60)
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
                            .frame(width: 64, height: 64)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.blue.opacity(0.8),
                                                Color.purple.opacity(0.8)
                                            ]),
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
                            .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                    }
                    .scaleEffect(showingAddHabit ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingAddHabit)
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
        )
        .sheet(isPresented: $showingAddHabit) {
            AddHabitView()
        }
        .sheet(isPresented: $showingHabitDetail) {
            if let habit = selectedHabit {
                HabitDetailView(habit: habit)
            }
        }
    }
    
    @ViewBuilder
    private var errorContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Service Not Available")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Unable to load habit service. Please restart the app.")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func statsSection(habitService: HabitService) -> some View {
        VStack(spacing: 16) {
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
                
                StatCard(
                    title: "Longest Streak",
                    value: "\(habitService.longestStreak())",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func habitsSection(habitService: HabitService) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            let sortedHabits = habitService.sortedHabits()
            if !sortedHabits.isEmpty {
                Text("Your Habits")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                
                LazyVStack(spacing: 16) {
                    ForEach(sortedHabits) { habit in
                        HabitCard(habit: habit) {
                            selectedHabit = habit
                            showingHabitDetail = true
                        }
                        .padding(.horizontal, 24)
                    }
                }
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.4))
            
            VStack(spacing: 16) {
                Text("Start Your Journey")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Add your first habit and begin building the life you want.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
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
        let hour = Calendar.current.component(.hour, from: Date())
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
    
    private func refreshHabits() async {
        await Task { @MainActor in
            print("🔄 DashboardView: Refreshing habits")
            habitService?.loadHabits()
        }.value
    }
}

// MARK: - Floating Orbs Background Component

struct FloatingOrbs: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Large orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.15),
                            Color.blue.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 20)
                .offset(
                    x: animate ? -50 : 50,
                    y: animate ? -80 : 80
                )
                .animation(
                    .easeInOut(duration: 8)
                    .repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Medium orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.12),
                            Color.purple.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 15)
                .offset(
                    x: animate ? 80 : -80,
                    y: animate ? 100 : -100
                )
                .animation(
                    .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true),
                    value: animate
                )
            
            // Small orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.indigo.opacity(0.1),
                            Color.indigo.opacity(0.03),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 10)
                .offset(
                    x: animate ? -30 : 30,
                    y: animate ? -120 : 120
                )
                .animation(
                    .easeInOut(duration: 10)
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
}

// MARK: - Preview

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
} 