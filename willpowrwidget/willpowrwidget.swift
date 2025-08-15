//
//  willpowrwidget.swift
//  willpowrwidget
//
//  Created by Sukhman Singh on 8/15/25.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct HabitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitWidgetEntry {
        let placeholderData = HabitWidgetData(
            id: "placeholder",
            name: "Daily Walk",
            iconName: "figure.walk",
            habitType: .build,
            streak: 15,
            longestStreak: 30,
            isCompleted: true,
            lastCompletionDate: Date(),
            goalTarget: 10000,
            goalUnit: .steps,
            currentProgress: 7500,
            activityData: generatePlaceholderActivity(),
            daysToShow: 90
        )
        
        return HabitWidgetEntry(
            date: Date(),
            habitData: placeholderData,
            configuration: HabitSelectionIntent()
        )
    }
    
    func snapshot(for configuration: HabitSelectionIntent, in context: Context) async -> HabitWidgetEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        
        let habitData = WidgetDataProvider.shared.fetchHabitData(for: configuration.habit?.id)
        return HabitWidgetEntry(
            date: Date(),
            habitData: habitData ?? generateSampleData(),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: HabitSelectionIntent, in context: Context) async -> Timeline<HabitWidgetEntry> {
        var entries: [HabitWidgetEntry] = []
        let currentDate = Date()
        
        // Fetch habit data
        let habitData = WidgetDataProvider.shared.fetchHabitData(for: configuration.habit?.id)
        
        // Create entries for the next 24 hours, updating every hour
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = HabitWidgetEntry(
                date: entryDate,
                habitData: habitData,
                configuration: configuration
            )
            entries.append(entry)
        }
        
        // Update timeline at the end of the day for fresh data
        let tomorrow = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
        return Timeline(entries: entries, policy: .after(tomorrow))
    }
    
    private func generatePlaceholderActivity() -> [DayActivity] {
        var activities: [DayActivity] = []
        let calendar = Calendar.current
        
        for dayOffset in 0..<90 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let randomProgress = Double.random(in: 0...1)
                activities.append(DayActivity(
                    date: date,
                    isCompleted: randomProgress > 0.3,
                    progressPercentage: randomProgress
                ))
            }
        }
        
        return activities.reversed()
    }
    
    private func generateSampleData() -> HabitWidgetData {
        return HabitWidgetData(
            id: "sample",
            name: "Exercise",
            iconName: "dumbbell.fill",
            habitType: .build,
            streak: 7,
            longestStreak: 14,
            isCompleted: false,
            lastCompletionDate: nil,
            goalTarget: 30,
            goalUnit: .minutes,
            currentProgress: 15,
            activityData: generatePlaceholderActivity(),
            daysToShow: 90
        )
    }
}

// MARK: - Widget Entry View

struct HabitWidgetEntryView: View {
    var entry: HabitWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if let habitData = entry.habitData {
            switch widgetFamily {
            case .systemSmall:
                SmallHabitWidget(habitData: habitData)
            case .systemMedium:
                MediumHabitWidget(habitData: habitData)
            case .systemLarge:
                LargeHabitWidget(habitData: habitData)
            default:
                SmallHabitWidget(habitData: habitData)
            }
        } else {
            EmptyWidgetView()
        }
    }
}

// MARK: - Small Widget

struct SmallHabitWidget: View {
    let habitData: HabitWidgetData
    
    var body: some View {
        VStack(spacing: 10) {
                // Header with habit name and icon
                HStack(spacing: 6) {
                    Image(systemName: habitData.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(habitData.habitType == .build ? .blue : .red)
                    
                    Text(habitData.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                // Mini activity grid
                WidgetActivityGrid(
                    habitData: habitData,
                    widgetFamily: .systemSmall
                )
                .frame(maxHeight: 60)
                
                Spacer(minLength: 0)
                
                // Bottom stats
                HStack {
                    // Streak
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("\(habitData.streak)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Status
                    HStack(spacing: 3) {
                        Image(systemName: habitData.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 11))
                            .foregroundColor(habitData.isCompletedToday ? .green : .orange)
                        Text(habitData.isCompletedToday ? "Done" : "Todo")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(habitData.isCompletedToday ? .green : .orange)
                    }
                }
        }
        .padding(12)
    }
}

// MARK: - Medium Widget

struct MediumHabitWidget: View {
    let habitData: HabitWidgetData
    
    var body: some View {
        HStack(spacing: 16) {
                // Left side - Info
                VStack(alignment: .leading, spacing: 12) {
                    // Habit name with icon
                    HStack(spacing: 6) {
                        Image(systemName: habitData.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(habitData.habitType == .build ? .blue : .red)
                        
                        Text(habitData.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 6) {
                        // Streak
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text("\(habitData.streak) day streak")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // Progress
                        if habitData.goalUnit != .none {
                            HStack(spacing: 6) {
                                ProgressBar(progress: habitData.progressPercentage)
                                    .frame(width: 80, height: 4)
                                Text("\(Int(habitData.progressPercentage * 100))%")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Status
                        HStack(spacing: 4) {
                            Image(systemName: habitData.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                                .foregroundColor(habitData.isCompletedToday ? .green : .orange)
                            Text(habitData.isCompletedToday ? "Completed today" : "Pending today")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(habitData.isCompletedToday ? .green : .orange)
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side - Activity grid
                VStack(alignment: .trailing, spacing: 6) {
                    Text("Last 60 days")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    WidgetActivityGrid(
                        habitData: habitData,
                        widgetFamily: .systemMedium
                    )
                    
                    Spacer()
                }
        }
        .padding()
    }
}

// MARK: - Large Widget

struct LargeHabitWidget: View {
    let habitData: HabitWidgetData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    // Habit info
                    HStack(spacing: 8) {
                        Image(systemName: habitData.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(habitData.habitType == .build ? .blue : .red)
                        
                        Text(habitData.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Type badge
                        Text(habitData.habitType == .build ? "BUILD" : "QUIT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(habitData.habitType == .build ? 
                                         Color.blue.opacity(0.3) : Color.red.opacity(0.3))
                            )
                    }
                }
                
                // Stats row
                HStack(spacing: 20) {
                    // Current streak
                    StatCard(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Current",
                        value: "\(habitData.streak)",
                        subtitle: "days"
                    )
                    
                    // Best streak
                    StatCard(
                        icon: "trophy.fill",
                        iconColor: .yellow,
                        title: "Best",
                        value: "\(habitData.longestStreak)",
                        subtitle: "days"
                    )
                    
                    // Today's progress
                    if habitData.goalUnit != .none {
                        StatCard(
                            icon: "target",
                            iconColor: .green,
                            title: "Progress",
                            value: "\(Int(habitData.progressPercentage * 100))%",
                            subtitle: habitData.displayProgress
                        )
                    }
                    
                    // Status
                    StatCard(
                        icon: habitData.isCompletedToday ? "checkmark.circle.fill" : "circle",
                        iconColor: habitData.isCompletedToday ? .green : .orange,
                        title: "Today",
                        value: habitData.isCompletedToday ? "Done" : "Todo",
                        subtitle: nil
                    )
                    
                    Spacer()
                }
                
                // Activity grid
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity Overview - Last 90 days")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    WidgetActivityGrid(
                        habitData: habitData,
                        widgetFamily: .systemLarge
                    )
                }
                
                Spacer()
        }
        .padding()
    }
}

// MARK: - Empty Widget View

struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Select a Habit")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Long press to configure")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress)
            }
        }
    }
}

// MARK: - Widget Configuration

struct willpowrwidget: Widget {
    let kind: String = "willpowrwidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: HabitSelectionIntent.self,
            provider: HabitProvider()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.05, blue: 0.15),
                            Color(red: 0.1, green: 0.1, blue: 0.2),
                            Color(red: 0.15, green: 0.1, blue: 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Habit Activity Chart")
        .description("Track your habit progress with a visual activity chart")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    willpowrwidget()
} timeline: {
    let sampleData = HabitWidgetData(
        id: "preview",
        name: "Meditate",
        iconName: "brain.head.profile",
        habitType: .build,
        streak: 15,
        longestStreak: 30,
        isCompleted: true,
        lastCompletionDate: Date(),
        goalTarget: 10,
        goalUnit: .minutes,
        currentProgress: 10,
        activityData: [],
        daysToShow: 49
    )
    HabitWidgetEntry(date: .now, habitData: sampleData, configuration: HabitSelectionIntent())
}

#Preview(as: .systemMedium) {
    willpowrwidget()
} timeline: {
    let sampleData = HabitWidgetData(
        id: "preview",
        name: "Daily Exercise",
        iconName: "figure.run",
        habitType: .build,
        streak: 30,
        longestStreak: 45,
        isCompleted: false,
        lastCompletionDate: nil,
        goalTarget: 30,
        goalUnit: .minutes,
        currentProgress: 15,
        activityData: [],
        daysToShow: 60
    )
    HabitWidgetEntry(date: .now, habitData: sampleData, configuration: HabitSelectionIntent())
}

#Preview(as: .systemLarge) {
    willpowrwidget()
} timeline: {
    let sampleData = HabitWidgetData(
        id: "preview",
        name: "Quit Smoking",
        iconName: "smoke.fill",
        habitType: .quit,
        streak: 7,
        longestStreak: 14,
        isCompleted: true,
        lastCompletionDate: Date(),
        goalTarget: 0,
        goalUnit: .none,
        currentProgress: 0,
        activityData: [],
        daysToShow: 90
    )
    HabitWidgetEntry(date: .now, habitData: sampleData, configuration: HabitSelectionIntent())
}