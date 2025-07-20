import Foundation
import SwiftUI

/// DateManager provides centralized date management with debugging capabilities
/// Allows overriding the current date for testing streak functionality
class DateManager: ObservableObject {
    @Published private var overrideDate: Date?
    @Published var dateDidChange: Date = Date() // Triggers UI refresh when date changes
    
    /// The current date - either real date or debug override
    var currentDate: Date {
        return overrideDate ?? Date()
    }
    
    /// Whether we're in debug mode (date is overridden)
    var isDebugging: Bool {
        return overrideDate != nil
    }
    
    /// Reset to real current date
    func resetToToday() {
        overrideDate = nil
        notifyDateChange()
    }
    
    /// Set a specific debug date
    func setDebugDate(_ date: Date) {
        overrideDate = date
        notifyDateChange()
    }
    
    /// Move debug date forward by one day
    func moveForwardOneDay() {
        let currentDate = self.currentDate
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        setDebugDate(nextDay)
    }
    
    /// Move debug date backward by one day
    func moveBackwardOneDay() {
        let currentDate = self.currentDate
        let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        setDebugDate(previousDay)
    }
    
    /// Notify that the date has changed - triggers UI refresh
    private func notifyDateChange() {
        dateDidChange = Date()
    }
    
    /// Helper method to check if a date is today (relative to current/debug date)
    func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, inSameDayAs: currentDate)
    }
    
    /// Helper method to check if a date is yesterday (relative to current/debug date)
    func isYesterday(_ date: Date) -> Bool {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: yesterday)
    }
    
    /// Get a date by adding days to the current date
    func dateByAdding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: currentDate) ?? currentDate
    }
    
    /// Get days between two dates
    func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    /// Format date for debugging display
    func formatDebugDate() -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: currentDate)
    }
} 