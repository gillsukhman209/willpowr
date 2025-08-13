import SwiftUI

struct HabitContributionGrid: View {
    let habit: Habit
    let daysToShow: Int
    @State private var selectedDate: Date?
    @State private var hoveredDate: Date?
    
    // Grid configuration
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    private let weeksToShow: Int
    
    init(habit: Habit, daysToShow: Int = 365) {
        self.habit = habit
        self.daysToShow = daysToShow
        // Calculate actual weeks to show based on days
        self.weeksToShow = min(13, (daysToShow / 7) + 1) // Show max 13 weeks for better layout
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Grid container
            HStack(spacing: 0) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    // Month labels
                    monthLabelsNew
                    
                    HStack(alignment: .top, spacing: 10) {
                        // Day of week labels
                        dayOfWeekLabels
                        
                        // Grid of contribution cells
                        contributionGridNew
                    }
                }
                
                Spacer()
            }
            
            // Legend
            legendNew
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .frame(height: 200)
    }
    
    // MARK: - Month Labels
    
    private var monthLabelsNew: some View {
        HStack(spacing: cellSpacing) {
            ForEach(getMonthLabels(), id: \.0) { month, weekSpan in
                Text(month)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: CGFloat(weekSpan) * (cellSize + cellSpacing) - cellSpacing, alignment: .leading)
            }
        }
        .padding(.leading, 35) // Align with grid
    }
    
    private func getMonthLabels() -> [(String, Int)] {
        var labels: [(String, Int)] = []
        let calendar = Calendar.current
        
        var currentMonth = ""
        var weekCount = 0
        
        for week in 0..<weeksToShow {
            if let date = getDateForWeek(week) {
                let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: date) - 1]
                
                if monthName != currentMonth {
                    if !currentMonth.isEmpty {
                        labels.append((currentMonth, weekCount))
                    }
                    currentMonth = monthName
                    weekCount = 1
                } else {
                    weekCount += 1
                }
            }
        }
        
        if !currentMonth.isEmpty {
            labels.append((currentMonth, weekCount))
        }
        
        return labels
    }
    
    private func getDateForWeek(_ weekOffset: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        let weeksAgo = weeksToShow - weekOffset - 1
        return calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today)
    }
    
    private var monthLabels: some View {
        HStack(spacing: 0) {
            // Empty space for day labels
            Color.clear
                .frame(width: 30)
            
            HStack(spacing: cellSpacing) {
                ForEach(monthLabelData, id: \.month) { data in
                    Text(data.month)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: CGFloat(data.weeks) * (cellSize + cellSpacing) - cellSpacing, alignment: .leading)
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(height: 16)
    }
    
    // MARK: - Day of Week Labels
    
    private var dayOfWeekLabels: some View {
        VStack(spacing: cellSpacing) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                Text(day)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20, height: cellSize)
            }
        }
    }
    
    // MARK: - Contribution Grid
    
    private var contributionGridNew: some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<weeksToShow, id: \.self) { weekIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let date = getDateForCell(weekIndex: weekIndex, dayIndex: dayIndex)
                        
                        if let date = date, date <= Date() {
                            ContributionCellNew(
                                date: date,
                                habit: habit,
                                isSelected: selectedDate == date
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = selectedDate == date ? nil : date
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.03))
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
    
    private func getDateForCell(weekIndex: Int, dayIndex: Int) -> Date? {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate weeks ago from today
        let weeksAgo = weeksToShow - weekIndex - 1
        
        // Get the date for that week
        guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today) else { return nil }
        
        // Get the Monday of that week
        let weekday = calendar.component(.weekday, from: weekDate)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: weekDate) else { return nil }
        
        // Add the day offset
        return calendar.date(byAdding: .day, value: dayIndex, to: monday)
    }
    
    private var contributionGrid: some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<weeksToShow, id: \.self) { weekIndex in
                VStack(spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let date = getDateForCell(weekIndex: weekIndex, dayIndex: dayIndex) {
                            ContributionCell(
                                date: date,
                                habit: habit,
                                isHovered: hoveredDate == date,
                                isSelected: selectedDate == date
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDate = selectedDate == date ? nil : date
                                }
                            }
                            .onHover { isHovering in
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    hoveredDate = isHovering ? date : nil
                                }
                            }
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Legend
    
    private var legendNew: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 2) {
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(getColorForLevel(Double(level) / 4.0))
                        .frame(width: 10, height: 10)
                }
            }
            
            Text("More")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Spacer()
            
            if let selectedDate = selectedDate,
               let entry = habit.entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(DesignTokens.Colors.electricBlue)
                        .frame(width: 6, height: 6)
                    
                    Text(formatDate(selectedDate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(entry.displayProgress)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(DesignTokens.Colors.electricBlue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                )
            }
        }
    }
    
    private func getColorForLevel(_ level: Double) -> Color {
        // Unified blue color scheme
        switch level {
        case 0:
            return Color.white.opacity(0.05)
        case 0..<0.25:
            return DesignTokens.Colors.electricBlue.opacity(0.3)
        case 0.25..<0.5:
            return DesignTokens.Colors.electricBlue.opacity(0.5)
        case 0.5..<0.75:
            return DesignTokens.Colors.electricBlue.opacity(0.7)
        default:
            return DesignTokens.Colors.electricBlue
        }
    }
    
    private var legend: some View {
        HStack(spacing: 16) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: cellSpacing) {
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(contributionColor(level: Double(level) / 4.0))
                        .frame(width: cellSize, height: cellSize)
                }
            }
            
            Text("More")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            if let selectedDate = selectedDate,
               let entry = habit.entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                HStack(spacing: 8) {
                    Text(formatDate(selectedDate))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(entry.displayProgress)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(contributionColor(for: entry))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var monthLabelData: [(month: String, weeks: Int)] {
        var result: [(month: String, weeks: Int)] = []
        let calendar = Calendar.current
        let today = Date()
        
        guard calendar.date(byAdding: .day, value: -daysToShow, to: today) != nil else { return result }
        
        var currentMonth = ""
        var weekCount = 0
        
        for weekIndex in 0..<weeksToShow {
            if let date = getDateForCell(weekIndex: weekIndex, dayIndex: 3) { // Check middle of week
                let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: date) - 1]
                
                if monthName != currentMonth {
                    if !currentMonth.isEmpty {
                        result.append((month: currentMonth, weeks: weekCount))
                    }
                    currentMonth = monthName
                    weekCount = 1
                } else {
                    weekCount += 1
                }
            }
        }
        
        if !currentMonth.isEmpty && weekCount > 0 {
            result.append((month: currentMonth, weeks: weekCount))
        }
        
        return result
    }
    
    private func contributionColor(for entry: HabitEntry) -> Color {
        if habit.habitType == .quit {
            // For quit habits: green if successful, red if failed
            return entry.isCompleted ? Color(red: 0.23, green: 0.65, blue: 0.36) : Color(red: 0.8, green: 0.2, blue: 0.2)
        } else {
            // For build habits: intensity based on progress
            let level = entry.progressPercentage
            return contributionColor(level: level)
        }
    }
    
    private func contributionColor(level: Double) -> Color {
        switch level {
        case 0:
            return Color(red: 0.09, green: 0.11, blue: 0.13) // Empty
        case 0..<0.25:
            return Color(red: 0.06, green: 0.27, blue: 0.16) // Low
        case 0.25..<0.5:
            return Color(red: 0.0, green: 0.43, blue: 0.20) // Medium-low
        case 0.5..<0.75:
            return Color(red: 0.15, green: 0.65, blue: 0.23) // Medium-high
        default:
            return Color(red: 0.23, green: 0.80, blue: 0.36) // High
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - New Contribution Cell with Unified Design

struct ContributionCellNew: View {
    let date: Date
    let habit: Habit
    let isSelected: Bool
    
    private var entry: HabitEntry? {
        habit.entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isToday ? Color.white : Color.clear, lineWidth: isToday ? 1.5 : 0)
            )
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    private var cellColor: Color {
        guard let entry = entry else {
            return Color.white.opacity(0.05) // Empty day
        }
        
        if habit.habitType == .quit {
            // For quit habits: blue if successful, red if failed
            if entry.isCompleted {
                return DesignTokens.Colors.electricBlue
            } else {
                return Color.red.opacity(0.7)
            }
        } else {
            // For build habits: intensity based on progress
            let level = entry.progressPercentage
            return getColorForProgress(level)
        }
    }
    
    private func getColorForProgress(_ level: Double) -> Color {
        switch level {
        case 0:
            return Color.white.opacity(0.05)
        case 0..<0.25:
            return DesignTokens.Colors.electricBlue.opacity(0.3)
        case 0.25..<0.5:
            return DesignTokens.Colors.electricBlue.opacity(0.5)
        case 0.5..<0.75:
            return DesignTokens.Colors.electricBlue.opacity(0.7)
        default:
            return DesignTokens.Colors.electricBlue
        }
    }
}

// MARK: - Original Contribution Cell (keep for backward compatibility)

struct ContributionCell: View {
    let date: Date
    let habit: Habit
    let isHovered: Bool
    let isSelected: Bool
    
    @State private var showTooltip = false
    
    private var entry: HabitEntry? {
        habit.entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(cellColor)
            .frame(width: 11, height: 11)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isHovered ? 1.2 : 1.0)
            .shadow(color: shadowColor, radius: shadowRadius)
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var cellColor: Color {
        guard let entry = entry else {
            return Color(red: 0.09, green: 0.11, blue: 0.13) // Empty day
        }
        
        if habit.habitType == .quit {
            // For quit habits: green if successful, red/orange if failed
            if entry.isCompleted {
                return Color(red: 0.23, green: 0.65, blue: 0.36) // Success green
            } else {
                return Color(red: 0.8, green: 0.2, blue: 0.2) // Failure red
            }
        } else {
            // For build habits: intensity based on progress percentage
            let level = entry.progressPercentage
            return contributionColor(level: level)
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return Color.white.opacity(0.8)
        } else if isSelected {
            return Color.white.opacity(0.6)
        } else if isHovered {
            return Color.white.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isToday {
            return 2
        } else if isSelected || isHovered {
            return 1
        } else {
            return 0
        }
    }
    
    private var shadowColor: Color {
        if isToday || isSelected {
            return cellColor.opacity(0.6)
        } else if isHovered {
            return cellColor.opacity(0.4)
        } else {
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        if isToday {
            return 4
        } else if isSelected {
            return 3
        } else if isHovered {
            return 2
        } else {
            return 0
        }
    }
    
    private func contributionColor(level: Double) -> Color {
        if habit.trackingMode == .automatic {
            // Blue theme for automatic habits
            switch level {
            case 0:
                return Color(red: 0.09, green: 0.11, blue: 0.13) // Empty
            case 0..<0.25:
                return Color(red: 0.06, green: 0.16, blue: 0.27) // Low blue
            case 0.25..<0.5:
                return Color(red: 0.0, green: 0.20, blue: 0.43) // Medium-low blue
            case 0.5..<0.75:
                return Color(red: 0.15, green: 0.36, blue: 0.65) // Medium-high blue
            default:
                return Color(red: 0.23, green: 0.46, blue: 0.80) // High blue
            }
        } else {
            // Green theme for manual habits
            switch level {
            case 0:
                return Color(red: 0.09, green: 0.11, blue: 0.13) // Empty
            case 0..<0.25:
                return Color(red: 0.06, green: 0.27, blue: 0.16) // Low green
            case 0.25..<0.5:
                return Color(red: 0.0, green: 0.43, blue: 0.20) // Medium-low green
            case 0.5..<0.75:
                return Color(red: 0.15, green: 0.65, blue: 0.23) // Medium-high green
            default:
                return Color(red: 0.23, green: 0.80, blue: 0.36) // High green
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Build habit with progress
        let buildHabit = Habit(
            name: "Daily Exercise",
            habitType: .build,
            iconName: "figure.run",
            goalTarget: 30,
            goalUnit: .minutes
        )
        
        HabitContributionGrid(habit: buildHabit, daysToShow: 365)
        
        // Quit habit
        let quitHabit = Habit(
            name: "Quit Smoking",
            habitType: .quit,
            iconName: "nosign"
        )
        
        HabitContributionGrid(habit: quitHabit, daysToShow: 365)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}