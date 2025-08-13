import SwiftUI

struct CompactHabitGrid: View {
    let habit: Habit
    let daysToShow: Int
    
    // Compact grid configuration
    private let cellSize: CGFloat = 8
    private let cellSpacing: CGFloat = 2
    private let maxWeeks = 13 // Show approximately 3 months
    
    init(habit: Habit, daysToShow: Int = 90) {
        self.habit = habit
        self.daysToShow = min(daysToShow, 90) // Cap at 90 days for compact view
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Text("Activity")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("Last \(daysToShow) days")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            
            // Grid
            HStack(spacing: cellSpacing) {
                ForEach(0..<min(maxWeeks, (daysToShow / 7) + 1), id: \.self) { weekIndex in
                    VStack(spacing: cellSpacing) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            if let date = dateForCell(weekIndex: weekIndex, dayIndex: dayIndex) {
                                CompactContributionCell(
                                    date: date,
                                    habit: habit
                                )
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Simple legend
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 0.09, green: 0.11, blue: 0.13))
                        .frame(width: 6, height: 6)
                    Text("No activity")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(getActivityColor())
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.06, green: 0.07, blue: 0.09).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func dateForCell(weekIndex: Int, dayIndex: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        // Start from daysToShow ago
        guard let startDate = calendar.date(byAdding: .day, value: -daysToShow + 1, to: today) else { return nil }
        
        // Adjust to start from Monday
        let weekday = calendar.component(.weekday, from: startDate)
        let daysFromMonday = (weekday + 5) % 7
        guard let adjustedStartDate = calendar.date(byAdding: .day, value: -daysFromMonday, to: startDate) else { return nil }
        
        // Calculate the date for this cell
        let daysToAdd = weekIndex * 7 + dayIndex
        guard let cellDate = calendar.date(byAdding: .day, value: daysToAdd, to: adjustedStartDate) else { return nil }
        
        // Don't show dates in the future or before our start date
        if cellDate > today || cellDate < startDate {
            return nil
        }
        
        return cellDate
    }
    
    private func getActivityColor() -> Color {
        if habit.trackingMode == .automatic {
            return Color(red: 0.23, green: 0.46, blue: 0.80) // Blue for automatic
        } else if habit.habitType == .quit {
            return Color(red: 0.23, green: 0.65, blue: 0.36) // Green for quit success
        } else {
            return Color(red: 0.95, green: 0.60, blue: 0.20) // Orange for manual
        }
    }
}

// MARK: - Compact Contribution Cell

struct CompactContributionCell: View {
    let date: Date
    let habit: Habit
    
    private var entry: HabitEntry? {
        habit.entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(width: 8, height: 8)
            .overlay(
                isToday ?
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1) : nil
            )
    }
    
    private var cellColor: Color {
        guard let entry = entry else {
            return Color(red: 0.09, green: 0.11, blue: 0.13) // Empty day
        }
        
        if habit.habitType == .quit {
            // For quit habits: green if successful, red if failed
            if entry.isCompleted {
                return Color(red: 0.23, green: 0.65, blue: 0.36).opacity(getOpacity(entry.progressPercentage))
            } else {
                return Color(red: 0.8, green: 0.2, blue: 0.2).opacity(0.8)
            }
        } else {
            // For build habits: color based on tracking mode
            let baseColor = habit.trackingMode == .automatic ?
                Color(red: 0.23, green: 0.46, blue: 0.80) : // Blue for automatic
                Color(red: 0.95, green: 0.60, blue: 0.20)   // Orange for manual
            
            return baseColor.opacity(getOpacity(entry.progressPercentage))
        }
    }
    
    private func getOpacity(_ level: Double) -> Double {
        switch level {
        case 0:
            return 0.1
        case 0..<0.25:
            return 0.3
        case 0.25..<0.5:
            return 0.5
        case 0.5..<0.75:
            return 0.7
        default:
            return 1.0
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Build habit with automatic tracking
        let autoHabit = Habit(
            name: "Daily Steps",
            habitType: .build,
            iconName: "figure.walk",
            goalTarget: 10000,
            goalUnit: .steps,
            trackingMode: .automatic
        )
        
        CompactHabitGrid(habit: autoHabit)
        
        // Build habit with manual tracking
        let manualHabit = Habit(
            name: "Read",
            habitType: .build,
            iconName: "book",
            goalTarget: 30,
            goalUnit: .minutes,
            trackingMode: .manual
        )
        
        CompactHabitGrid(habit: manualHabit)
        
        // Quit habit
        let quitHabit = Habit(
            name: "Quit Smoking",
            habitType: .quit,
            iconName: "nosign"
        )
        
        CompactHabitGrid(habit: quitHabit)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}