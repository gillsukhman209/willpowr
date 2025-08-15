//
//  WidgetActivityGrid.swift
//  willpowrwidget
//
//  Optimized activity grid views for widgets
//

import SwiftUI
import WidgetKit

// MARK: - Activity Grid for Widgets

struct WidgetActivityGrid: View {
    let habitData: HabitWidgetData
    let widgetFamily: WidgetFamily
    
    // Grid configuration based on widget size
    private var gridConfig: GridConfiguration {
        switch widgetFamily {
        case .systemSmall:
            return GridConfiguration(
                cellSize: 8,
                cellSpacing: 2,
                daysToShow: 49, // 7x7 grid
                weeksToShow: 7
            )
        case .systemMedium:
            return GridConfiguration(
                cellSize: 6,
                cellSpacing: 1.5,
                daysToShow: 60, // ~8.5 weeks
                weeksToShow: 9
            )
        case .systemLarge:
            return GridConfiguration(
                cellSize: 10,
                cellSpacing: 2,
                daysToShow: 90, // ~13 weeks
                weeksToShow: 13
            )
        default:
            return GridConfiguration(
                cellSize: 8,
                cellSpacing: 2,
                daysToShow: 49,
                weeksToShow: 7
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if widgetFamily == .systemLarge {
                // Month labels for large widget
                monthLabels
                    .padding(.bottom, 4)
            }
            
            HStack(alignment: .top, spacing: gridConfig.cellSpacing) {
                if widgetFamily == .systemLarge {
                    // Day labels for large widget
                    dayLabels
                }
                
                // Activity grid
                activityGrid
            }
            
            if widgetFamily != .systemSmall {
                // Legend for medium and large widgets
                legend
                    .padding(.top, 6)
            }
        }
    }
    
    // MARK: - Month Labels
    
    private var monthLabels: some View {
        HStack(spacing: 0) {
            if widgetFamily == .systemLarge {
                // Space for day labels
                Color.clear
                    .frame(width: 15)
            }
            
            HStack(spacing: gridConfig.cellSpacing) {
                ForEach(getMonthLabels(), id: \.month) { monthData in
                    Text(monthData.month)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(
                            width: CGFloat(monthData.weeks) * (gridConfig.cellSize + gridConfig.cellSpacing) - gridConfig.cellSpacing,
                            alignment: .leading
                        )
                }
            }
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Day Labels
    
    private var dayLabels: some View {
        VStack(spacing: gridConfig.cellSpacing) {
            let days = ["M", "T", "W", "T", "F", "S", "S"]
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                Text(day)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 12, height: gridConfig.cellSize)
            }
        }
    }
    
    // MARK: - Activity Grid
    
    private var activityGrid: some View {
        HStack(spacing: gridConfig.cellSpacing) {
            ForEach(0..<gridConfig.weeksToShow, id: \.self) { weekIndex in
                VStack(spacing: gridConfig.cellSpacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let activity = getActivity(weekIndex: weekIndex, dayIndex: dayIndex) {
                            RoundedRectangle(cornerRadius: gridConfig.cellSize > 8 ? 2 : 1)
                                .fill(activity.activityLevel.color(for: habitData.habitType))
                                .frame(width: gridConfig.cellSize, height: gridConfig.cellSize)
                                .overlay(
                                    // Today indicator
                                    Calendar.current.isDateInToday(activity.date) ?
                                    RoundedRectangle(cornerRadius: gridConfig.cellSize > 8 ? 2 : 1)
                                        .stroke(Color.white, lineWidth: 1)
                                    : nil
                                )
                        } else {
                            RoundedRectangle(cornerRadius: gridConfig.cellSize > 8 ? 2 : 1)
                                .fill(Color.white.opacity(0.03))
                                .frame(width: gridConfig.cellSize, height: gridConfig.cellSize)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Legend
    
    private var legend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
            
            HStack(spacing: 2) {
                ForEach(Array([ActivityLevel.none, .low, .medium, .high, .complete].enumerated()), id: \.offset) { index, level in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(level.color(for: habitData.habitType))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text("More")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.4))
            
            Spacer()
            
            // Current streak indicator
            if habitData.streak > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("\(habitData.streak) days")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getActivity(weekIndex: Int, dayIndex: Int) -> DayActivity? {
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate the date for this cell
        let totalDaysAgo = gridConfig.daysToShow - (weekIndex * 7 + dayIndex) - 1
        guard totalDaysAgo >= 0,
              let date = calendar.date(byAdding: .day, value: -totalDaysAgo, to: today) else {
            return nil
        }
        
        // Don't show future dates
        if date > today {
            return nil
        }
        
        // Find activity for this date
        return habitData.activityData.first { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
    }
    
    private func getMonthLabels() -> [(month: String, weeks: Int)] {
        var labels: [(month: String, weeks: Int)] = []
        let calendar = Calendar.current
        let today = Date()
        
        var currentMonth = ""
        var weekCount = 0
        
        for weekIndex in 0..<gridConfig.weeksToShow {
            let daysAgo = gridConfig.daysToShow - (weekIndex * 7) - 1
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                continue
            }
            
            let monthName = calendar.shortMonthSymbols[calendar.component(.month, from: date) - 1]
            
            if monthName != currentMonth {
                if !currentMonth.isEmpty {
                    labels.append((month: currentMonth, weeks: weekCount))
                }
                currentMonth = monthName
                weekCount = 1
            } else {
                weekCount += 1
            }
        }
        
        if !currentMonth.isEmpty {
            labels.append((month: currentMonth, weeks: weekCount))
        }
        
        return labels
    }
}

// MARK: - Grid Configuration

private struct GridConfiguration {
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let daysToShow: Int
    let weeksToShow: Int
}

// MARK: - Compact Stats View

struct WidgetCompactStats: View {
    let habitData: HabitWidgetData
    
    var body: some View {
        HStack(spacing: 12) {
            // Streak
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text("\(habitData.streak)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Divider()
                .frame(height: 30)
                .overlay(Color.white.opacity(0.2))
            
            // Progress
            VStack(spacing: 2) {
                Image(systemName: habitData.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundColor(habitData.isCompletedToday ? .green : .orange)
                Text(habitData.isCompletedToday ? "Done" : "Todo")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(habitData.isCompletedToday ? .green : .orange)
            }
            
            if habitData.goalUnit != .none {
                Divider()
                    .frame(height: 30)
                    .overlay(Color.white.opacity(0.2))
                
                // Goal Progress
                VStack(spacing: 2) {
                    CircularProgressView(progress: habitData.progressPercentage)
                        .frame(width: 20, height: 20)
                    Text("\(Int(habitData.progressPercentage * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}