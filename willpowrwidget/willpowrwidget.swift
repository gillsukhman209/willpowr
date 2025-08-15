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
        
        let config = HabitSelectionIntent()
        config.daysToShow = .ninety
        return HabitWidgetEntry(
            date: Date(),
            habitData: placeholderData,
            configuration: config
        )
    }
    
    func snapshot(for configuration: HabitSelectionIntent, in context: Context) async -> HabitWidgetEntry {
        if context.isPreview {
            return placeholder(in: context)
        }
        
        let daysToShow = configuration.daysToShow.intValue
        let habitData = WidgetDataProvider.shared.fetchHabitData(for: configuration.habit?.id, daysToShow: daysToShow)
        return HabitWidgetEntry(
            date: Date(),
            habitData: habitData ?? generateSampleData(daysToShow: daysToShow),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: HabitSelectionIntent, in context: Context) async -> Timeline<HabitWidgetEntry> {
        var entries: [HabitWidgetEntry] = []
        let currentDate = Date()
        
        // Fetch habit data with configured days
        let daysToShow = configuration.daysToShow.intValue
        let habitData = WidgetDataProvider.shared.fetchHabitData(for: configuration.habit?.id, daysToShow: daysToShow)
        
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
    
    private func generateSampleData(daysToShow: Int = 90) -> HabitWidgetData {
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
            daysToShow: daysToShow
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
        VStack(spacing: 0) {
            // Clean minimal header
            HStack {
                Text(habitData.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Streak with flame
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Text("\(habitData.streak)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.bottom, 6)
            
            // MAIN FOCUS: Activity Chart with controlled size
            HStack {
                Spacer()
                WidgetActivityGrid(
                    habitData: habitData,
                    widgetFamily: .systemSmall
                )
                Spacer()
            }
            .frame(maxWidth: .infinity, idealHeight: 60, maxHeight: 60) // Fixed height for small widget
            
            Spacer(minLength: 2)
            
            // Completion indicator (subtle)
            if habitData.isCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            }
        }
        .padding(10) // Professional margins for small widget
    }
}

// MARK: - Medium Widget

struct MediumHabitWidget: View {
    let habitData: HabitWidgetData
    
    var body: some View {
        VStack(spacing: 0) {
            // Professional header with proper hierarchy
            HStack {
                // Left: Habit name with icon
                HStack(spacing: 5) {
                    Image(systemName: habitData.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(habitData.habitType == .build ? .blue : .red)
                    
                    Text(habitData.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right: Streak with flame
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    Text("\(habitData.streak)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.bottom, 8)
            
            // MAIN FOCUS: Activity Chart with controlled height
            HStack {
                Spacer()
                WidgetActivityGrid(
                    habitData: habitData,
                    widgetFamily: .systemMedium
                )
                Spacer()
            }
            .frame(maxWidth: .infinity, idealHeight: 80, maxHeight: 80) // Fixed height to preserve header/footer
            
            Spacer(minLength: 4)
            
            // Subtle footer
            Text("Last \(habitData.daysToShow) days")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12) // Professional margins
    }
}

// MARK: - Large Widget

struct LargeHabitWidget: View {
    let habitData: HabitWidgetData
    
    var body: some View {
        VStack(spacing: 0) {
            // Professional header with clear hierarchy
            HStack {
                // Left: Habit name with icon
                HStack(spacing: 6) {
                    Image(systemName: habitData.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(habitData.habitType == .build ? .blue : .red)
                    
                    Text(habitData.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Right: Essential stats in clean layout
                HStack(spacing: 15) {
                    // Current streak
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("\(habitData.streak)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        Text("current")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Best streak
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("\(habitData.longestStreak)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        Text("best")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Today status
                    if habitData.isCompletedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.bottom, 12)
            
            // MAIN FOCUS: Activity Chart with controlled proportions
            HStack {
                Spacer()
                WidgetActivityGrid(
                    habitData: habitData,
                    widgetFamily: .systemLarge
                )
                Spacer()
            }
            .frame(maxWidth: .infinity, idealHeight: 120, maxHeight: 120) // Fixed height for proper layout
            
            Spacer(minLength: 6)
            
            // Clean footer
            Text("Last \(habitData.daysToShow) days")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(14) // Professional margins for large widget
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
    HabitWidgetEntry(date: .now, habitData: sampleData, configuration: HabitSelectionIntent(habit: nil, daysToShow: .thirty))
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
    HabitWidgetEntry(date: .now, habitData: sampleData, configuration: HabitSelectionIntent(habit: nil, daysToShow: .thirty))
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
    HabitWidgetEntry(date: .now, habitData: sampleData, configuration: HabitSelectionIntent(habit: nil, daysToShow: .thirty))
}