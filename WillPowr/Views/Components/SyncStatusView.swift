import SwiftUI

struct SyncStatusView: View {
    @EnvironmentObject var habitService: HabitService
    @EnvironmentObject var backgroundSyncService: BackgroundSyncService
    @State private var showDetails = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Sync status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .opacity(habitService.syncStatus.isActive ? 1.0 : 0.6)
                .scaleEffect(habitService.syncStatus.isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: habitService.syncStatus.isActive)
            
            // Status text
            Text(statusText)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Last sync time
            if let lastSync = lastSyncTime {
                Text("• \(timeAgoString(lastSync))")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .onTapGesture {
            showDetails.toggle()
        }
        .sheet(isPresented: $showDetails) {
            SyncStatusDetailView()
                .environmentObject(habitService)
                .environmentObject(backgroundSyncService)
        }
    }
    
    private var statusColor: Color {
        switch habitService.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var statusText: String {
        let autoHabitsCount = habitService.getAutomaticTrackingHabits().count
        
        if autoHabitsCount == 0 {
            return "No auto habits"
        } else {
            return habitService.syncStatus.displayText
        }
    }
    
    private var lastSyncTime: Date? {
        // Use the most recent sync time from either service
        let habitSync = habitService.lastSyncTime
        let backgroundSync = backgroundSyncService.lastBackgroundSync
        
        switch (habitSync, backgroundSync) {
        case (let h?, let b?):
            return max(h, b)
        case (let h?, nil):
            return h
        case (nil, let b?):
            return b
        case (nil, nil):
            return nil
        }
    }
    
    private func timeAgoString(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct SyncStatusDetailView: View {
    @EnvironmentObject var habitService: HabitService
    @EnvironmentObject var backgroundSyncService: BackgroundSyncService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Current Status Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sync Status")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(habitService.syncStatus.displayText)
                            .font(.body)
                    }
                    
                    if case .failed(let error) = habitService.syncStatus {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Divider()
                
                // Background Sync Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Sync")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(backgroundSyncService.isObservingHealthChanges ? .green : .gray)
                            .frame(width: 12, height: 12)
                        
                        Text(backgroundSyncService.isObservingHealthChanges ? "Active" : "Inactive")
                            .font(.body)
                    }
                    
                    if let lastBgSync = backgroundSyncService.lastBackgroundSync {
                        Text("Last background sync: \(lastBgSync, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No background sync yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Automatic Habits
                VStack(alignment: .leading, spacing: 12) {
                    Text("Automatic Tracking")
                        .font(.headline)
                    
                    let autoHabits = habitService.getAutomaticTrackingHabits()
                    
                    if autoHabits.isEmpty {
                        Text("No habits using automatic tracking")
                            .font(.body)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(autoHabits.count) habit\(autoHabits.count == 1 ? "" : "s") using automatic tracking:")
                            .font(.body)
                        
                        ForEach(autoHabits, id: \.id) { habit in
                            HStack {
                                Image(systemName: habit.iconName)
                                    .foregroundColor(.blue)
                                Text(habit.name)
                                Spacer()
                                Text("\(habit.goalUnit.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sync Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var statusColor: Color {
        switch habitService.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    SyncStatusView()
}