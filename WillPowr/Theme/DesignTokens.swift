import SwiftUI

// MARK: - Design Tokens for Futuristic Minimalist Theme
enum DesignTokens {
    
    // MARK: - Colors
    enum Colors {
        // Base Colors
        static let pureBlack = Color(hex: "000000")
        static let offWhite = Color(hex: "FAFAFA")
        static let darkGray = Color(hex: "0A0A0A")
        static let lightGray = Color(hex: "1A1A1A")
        
        // Accent Colors
        static let neonGreen = Color(hex: "00FF41")
        static let hotPink = Color(hex: "FF0080")
        static let electricBlue = Color(hex: "00D4FF")
        static let warningOrange = Color(hex: "FF6B00")
        
        // Functional Colors
        static let success = neonGreen
        static let danger = hotPink
        static let primary = electricBlue
        static let warning = warningOrange
        
        // Glow Effects
        static func glow(for color: Color, intensity: Double = 0.6) -> Color {
            return color.opacity(intensity)
        }
    }
    
    // MARK: - Typography
    enum Typography {
        // Font Weights
        static let ultraLight: Font.Weight = .ultraLight
        static let regular: Font.Weight = .regular
        static let bold: Font.Weight = .bold
        static let black: Font.Weight = .black
        
        // Font Sizes
        static let giantTitle: CGFloat = 80
        static let heroTitle: CGFloat = 60
        static let largeTitle: CGFloat = 48
        static let title: CGFloat = 32
        static let headline: CGFloat = 24
        static let body: CGFloat = 18
        static let caption: CGFloat = 14
        static let micro: CGFloat = 11
        
        // Letter Spacing
        static let tightSpacing: CGFloat = -0.04
        static let normalSpacing: CGFloat = 0
        static let wideSpacing: CGFloat = 0.08
        static let ultraWideSpacing: CGFloat = 0.16
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let micro: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xlarge: CGFloat = 32
        static let xxlarge: CGFloat = 48
        static let giant: CGFloat = 64
        static let massive: CGFloat = 96
    }
    
    // MARK: - Radius
    enum Radius {
        static let none: CGFloat = 0
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 16
        static let pill: CGFloat = 999
    }
    
    // MARK: - Animation
    enum Animation {
        static let microDuration: Double = 0.1
        static let fastDuration: Double = 0.2
        static let normalDuration: Double = 0.3
        static let slowDuration: Double = 0.5
        static let verySlowDuration: Double = 0.8
        
        static let springResponse: Double = 0.4
        static let springDamping: Double = 0.75
        
        static func spring(duration: Double = normalDuration) -> SwiftUI.Animation {
            .spring(response: duration, dampingFraction: springDamping)
        }
        
        static func easeOut(duration: Double = normalDuration) -> SwiftUI.Animation {
            .easeOut(duration: duration)
        }
    }
    
    // MARK: - Shadows
    enum Shadows {
        static func glow(color: Color, radius: CGFloat = 20) -> Shadow {
            Shadow(color: color, radius: radius, x: 0, y: 0)
        }
        
        static func elevation(level: Int) -> Shadow {
            let radius = CGFloat(level * 4)
            let y = CGFloat(level * 2)
            return Shadow(
                color: Colors.pureBlack.opacity(0.2),
                radius: radius,
                x: 0,
                y: y
            )
        }
    }
}

// MARK: - Shadow Type
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Custom Font Modifiers
extension View {
    func giantTitle() -> some View {
        self.font(.system(size: DesignTokens.Typography.giantTitle, weight: .black))
            .tracking(DesignTokens.Typography.tightSpacing)
    }
    
    func heroTitle() -> some View {
        self.font(.system(size: DesignTokens.Typography.heroTitle, weight: .black))
            .tracking(DesignTokens.Typography.tightSpacing)
    }
    
    func largeTitle() -> some View {
        self.font(.system(size: DesignTokens.Typography.largeTitle, weight: .bold))
            .tracking(DesignTokens.Typography.tightSpacing)
    }
    
    func headline() -> some View {
        self.font(.system(size: DesignTokens.Typography.headline, weight: .bold))
    }
    
    func body() -> some View {
        self.font(.system(size: DesignTokens.Typography.body, weight: .regular))
    }
    
    func caption() -> some View {
        self.font(.system(size: DesignTokens.Typography.caption, weight: .regular))
    }
    
    func micro() -> some View {
        self.font(.system(size: DesignTokens.Typography.micro, weight: .regular))
            .tracking(DesignTokens.Typography.wideSpacing)
    }
}

// MARK: - Glow Effect
extension View {
    func glow(color: Color, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - Brutalist Border
extension View {
    func brutalistBorder(color: Color = DesignTokens.Colors.offWhite, width: CGFloat = 2) -> some View {
        self.overlay(
            Rectangle()
                .strokeBorder(color, lineWidth: width)
        )
    }
}