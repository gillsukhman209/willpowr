//
//  willpowrwidget.swift
//  willpowrwidget
//
//  Created by Sukhman Singh on 8/15/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), habitName: "Meditate", streak: 7, completedToday: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), habitName: "Exercise", streak: 15, completedToday: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        // For now, create a simple test entry
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, habitName: "Test Habit", streak: 10, completedToday: true)
        entries.append(entry)
        
        // Refresh timeline every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let habitName: String
    let streak: Int
    let completedToday: Bool
}

struct willpowrwidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            // Background gradient similar to main app
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // Habit name
                Text(entry.habitName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                // Streak
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                    
                    Text("\(entry.streak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("day streak")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Status indicator
                HStack(spacing: 4) {
                    Image(systemName: entry.completedToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12))
                        .foregroundColor(entry.completedToday ? .green : .orange)
                    
                    Text(entry.completedToday ? "Done" : "Pending")
                        .font(.system(size: 11))
                        .foregroundColor(entry.completedToday ? .green : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                )
            }
            .padding()
        }
    }
}

struct MediumWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Left side - Habit info
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.habitName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("\(entry.streak) day streak")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: entry.completedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(entry.completedToday ? .green : .orange)
                        
                        Text(entry.completedToday ? "Completed today" : "Pending today")
                            .font(.system(size: 12))
                            .foregroundColor(entry.completedToday ? .green : .orange)
                    }
                }
                
                Spacer()
                
                // Right side - Mini activity grid (placeholder for now)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last 7 days")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Simple activity indicators
                    HStack(spacing: 2) {
                        ForEach(0..<7) { day in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(day < 5 ? Color.green.opacity(0.7) : Color.white.opacity(0.1))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct LargeWidgetView: View {
    let entry: SimpleEntry
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.habitName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Text("\(entry.streak) days")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.3))
                            
                            HStack(spacing: 4) {
                                Image(systemName: entry.completedToday ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(entry.completedToday ? .green : .orange)
                                Text(entry.completedToday ? "Done" : "Pending")
                                    .font(.system(size: 12))
                                    .foregroundColor(entry.completedToday ? .green : .orange)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Activity grid placeholder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity - Last 30 days")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Simple grid for testing
                    VStack(spacing: 3) {
                        ForEach(0..<5) { week in
                            HStack(spacing: 3) {
                                ForEach(0..<7) { day in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(randomActivityColor())
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    func randomActivityColor() -> Color {
        let random = Double.random(in: 0...1)
        if random < 0.2 {
            return Color.white.opacity(0.05)
        } else if random < 0.5 {
            return Color.blue.opacity(0.3)
        } else if random < 0.75 {
            return Color.blue.opacity(0.6)
        } else {
            return Color.blue
        }
    }
}

struct willpowrwidget: Widget {
    let kind: String = "willpowrwidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            willpowrwidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your habit progress and streaks")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    willpowrwidget()
} timeline: {
    SimpleEntry(date: .now, habitName: "Meditate", streak: 7, completedToday: true)
    SimpleEntry(date: .now, habitName: "Exercise", streak: 15, completedToday: false)
}

#Preview(as: .systemMedium) {
    willpowrwidget()
} timeline: {
    SimpleEntry(date: .now, habitName: "Daily Walk", streak: 30, completedToday: true)
}

#Preview(as: .systemLarge) {
    willpowrwidget()
} timeline: {
    SimpleEntry(date: .now, habitName: "Reading", streak: 45, completedToday: false)
}