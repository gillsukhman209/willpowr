import SwiftUI

extension Color {
    // MARK: - Premium Dark Mode Colors
    
    static let primaryBackground = Color("PrimaryBackground")
    static let secondaryBackground = Color("SecondaryBackground")
    static let tertiaryBackground = Color("TertiaryBackground")
    
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let tertiaryText = Color("TertiaryText")
    
    static let accent = Color("AccentColor")
    static let success = Color.green
    static let failure = Color.red
    static let warning = Color.orange
    
    // MARK: - Glassmorphism Colors
    
    static let glassBackground = Color.fallbackGlassBackground
    static let glassBorder = Color.fallbackGlassBorder
    static let glassShadow = Color.fallbackGlassShadow
    
    // MARK: - Habit Type Colors
    
    static let buildHabitGradientStart = Color.green
    static let buildHabitGradientEnd = Color.blue
    static let quitHabitGradientStart = Color.red
    static let quitHabitGradientEnd = Color.orange
    
    // MARK: - Streak Colors
    
    static let streakFire = Color.orange
    static let streakGold = Color.yellow
    static let streakPlatinum = Color.purple
    
    // MARK: - Fallback Colors (for development)
    
    static let fallbackPrimaryBackground = Color(red: 0.08, green: 0.08, blue: 0.10)
    static let fallbackSecondaryBackground = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let fallbackTertiaryBackground = Color(red: 0.16, green: 0.16, blue: 0.18)
    
    static let fallbackPrimaryText = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let fallbackSecondaryText = Color(red: 0.78, green: 0.78, blue: 0.80)
    static let fallbackTertiaryText = Color(red: 0.56, green: 0.56, blue: 0.58)
    
    static let fallbackGlassBackground = Color(red: 0.16, green: 0.16, blue: 0.18).opacity(0.6)
    static let fallbackGlassBorder = Color(red: 0.32, green: 0.32, blue: 0.34).opacity(0.5)
    static let fallbackGlassShadow = Color.black.opacity(0.3)
    
    // MARK: - Gradient Helpers
    
    static let buildHabitGradient = LinearGradient(
        colors: [buildHabitGradientStart, buildHabitGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let quitHabitGradient = LinearGradient(
        colors: [quitHabitGradientStart, quitHabitGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [primaryBackground, secondaryBackground],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassGradient = LinearGradient(
        colors: [glassBackground, glassBackground.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Streak Color by Number
    
    static func streakColor(for streakCount: Int) -> Color {
        switch streakCount {
        case 0:
            return tertiaryText
        case 1...7:
            return success
        case 8...30:
            return streakFire
        case 31...99:
            return streakGold
        default:
            return streakPlatinum
        }
    }
    
    // MARK: - Dynamic Color Support
    
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color(.systemBackground) == .white ? light : dark
    }
}

// MARK: - UIColor Extensions for System Integration

extension UIColor {
    static let primaryBackground = UIColor(named: "PrimaryBackground") ?? UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
    static let secondaryBackground = UIColor(named: "SecondaryBackground") ?? UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
    static let glassBackground = UIColor(named: "GlassBackground") ?? UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 0.6)
} 