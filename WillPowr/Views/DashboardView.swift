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
                // Background
                Color.black.ignoresSafeArea()
                
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
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WillPowr")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Build habits. Quit bad ones.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Debug trash button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color.red.opacity(0.1))
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
                .padding(.horizontal)
                
                // Stats Cards
                statsSection(habitService: habitService)
                
                // Habits Section
                habitsSection(habitService: habitService)
                
                Spacer(minLength: 100)
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
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
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
        .sheet(isPresented: $showingHabitDetail) {
            if let habit = selectedHabit {
                HabitDetailView(habit: habit)
            }
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
    
    @ViewBuilder
    private func statsSection(habitService: HabitService) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Habits",
                    value: "\(habitService.totalActiveHabits())",
                    icon: "target",
                    color: .gray
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
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func habitsSection(habitService: HabitService) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            let sortedHabits = habitService.sortedHabits()
            if !sortedHabits.isEmpty {
                Text("Your Habits")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(sortedHabits) { habit in
                        HabitCard(habit: habit) {
                            selectedHabit = habit
                            showingHabitDetail = true
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("Start Your Journey")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Add your first habit and begin building the life you want.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding(.top, 40)
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

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.fallbackPrimaryText)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.fallbackSecondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.fallbackGlassBackground)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.fallbackGlassBorder, lineWidth: 0.5)
                )
                .shadow(color: Color.fallbackGlassShadow, radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
} 