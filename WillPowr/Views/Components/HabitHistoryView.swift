import SwiftUI

struct HabitHistoryView: View {
    let habit: Habit
    @EnvironmentObject private var habitService: HabitService
    @State private var selectedPeriod: HistoryPeriod = .week
    @State private var showingAllEntries = false
    
    enum HistoryPeriod: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"
    }
    
    var filteredEntries: [HabitEntry] {
        let entries = habit.sortedEntries
        
        switch selectedPeriod {
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return entries.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            return entries.filter { $0.date >= monthAgo }
        case .all:
            return entries
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            
            if !filteredEntries.isEmpty {
                statisticsSection
                
                if habit.goalUnit != .none {
                    chartSection
                }
                
                entriesListSection
            } else {
                emptyStateView
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Period selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(HistoryPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if !filteredEntries.isEmpty {
                Text("\(filteredEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 15) {
                statCard(
                    title: "Total Days",
                    value: "\(filteredEntries.count)",
                    icon: "calendar",
                    color: DesignTokens.Colors.electricBlue
                )
                
                statCard(
                    title: "Success Rate",
                    value: "\(successRate)%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: DesignTokens.Colors.neonGreen
                )
                
                if habit.goalUnit != .none {
                    statCard(
                        title: "Average",
                        value: averageProgress,
                        icon: "chart.bar.fill",
                        color: DesignTokens.Colors.electricBlue
                    )
                }
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Chart")
                .font(.headline)
                .foregroundColor(.white)
            
            HabitProgressChart(entries: filteredEntries, habit: habit)
                .frame(height: 150)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
    }
    
    private var entriesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if filteredEntries.count > 10 {
                    Button(showingAllEntries ? "Show Less" : "Show All") {
                        showingAllEntries.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.electricBlue)
                }
            }
            
            let entriesToShow = showingAllEntries ? filteredEntries : Array(filteredEntries.prefix(10))
            
            LazyVStack(spacing: 8) {
                ForEach(entriesToShow, id: \.id) { entry in
                    HabitHistoryEntryRow(entry: entry, habit: habit)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No History Yet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Start tracking this habit to see your progress history here.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Computed Properties
    
    private var successRate: Int {
        guard !filteredEntries.isEmpty else { return 0 }
        let successfulEntries = filteredEntries.filter { $0.isCompleted || $0.isGoalMet }
        return Int((Double(successfulEntries.count) / Double(filteredEntries.count)) * 100)
    }
    
    private var averageProgress: String {
        guard !filteredEntries.isEmpty else { return "0" }
        let totalProgress = filteredEntries.reduce(0) { $0 + $1.progress }
        let average = totalProgress / Double(filteredEntries.count)
        
        if average == floor(average) {
            return "\(Int(average)) \(habit.goalUnit.displayName)"
        } else {
            return String(format: "%.1f \(habit.goalUnit.displayName)", average)
        }
    }
}

struct HabitHistoryEntryRow: View {
    let entry: HabitEntry
    let habit: Habit
    
    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.dayOfWeek)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Text(entry.shortDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(width: 50, alignment: .leading)
            
            // Status icon
            Image(systemName: entry.statusIcon)
                .font(.title3)
                .foregroundColor(statusColor(entry.statusColor))
            
            // Progress details
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayProgress)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if entry.habitType == .build && entry.goalUnit != .none {
                    ProgressView(value: entry.progressPercentage)
                        .tint(DesignTokens.Colors.electricBlue)
                        .scaleEffect(y: 0.8)
                }
            }
            
            Spacer()
            
            // Goal achievement indicator
            if entry.isGoalMet {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.neonGreen)
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
    
    private func statusColor(_ colorString: String) -> Color {
        switch colorString {
        case "green": return DesignTokens.Colors.neonGreen
        case "red": return .red
        case "orange": return .orange
        default: return .gray
        }
    }
}

struct HabitProgressChart: View {
    let entries: [HabitEntry]
    let habit: Habit
    
    var body: some View {
        GeometryReader { geometry in
            let chartEntries = entries.suffix(14).reversed() // Last 14 days, reversed for chronological order
            let maxValue = chartEntries.map { $0.progress }.max() ?? habit.goalTarget
            let adjustedMaxValue = max(maxValue, habit.goalTarget) * 1.1 // Add 10% padding
            
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Array(chartEntries.enumerated()), id: \.offset) { index, entry in
                    let height = adjustedMaxValue > 0 ? (entry.progress / adjustedMaxValue) * geometry.size.height : 0
                    let goalHeight = adjustedMaxValue > 0 ? (habit.goalTarget / adjustedMaxValue) * geometry.size.height : 0
                    
                    VStack(spacing: 2) {
                        // Bar
                        Rectangle()
                            .fill(
                                entry.isGoalMet ?
                                DesignTokens.Colors.neonGreen.gradient :
                                DesignTokens.Colors.electricBlue.opacity(0.6).gradient
                            )
                            .frame(height: max(height, 2))
                            .overlay(
                                // Goal line
                                Rectangle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    .frame(height: 1)
                                    .offset(y: height - goalHeight),
                                alignment: .bottom
                            )
                        
                        // Date label (show every other day for readability)
                        if index % 2 == 0 {
                            Text(dayLabel(for: entry.date))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

#Preview {
    let habit = Habit(
        name: "Walk Daily",
        habitType: .build,
        iconName: "figure.walk",
        goalTarget: 8000,
        goalUnit: .steps
    )
    
    HabitHistoryView(habit: habit)
        .background(Color.black)
}