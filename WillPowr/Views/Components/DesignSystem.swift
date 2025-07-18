import SwiftUI

// MARK: - Design System Colors
extension Color {
    static let primary = Color("AccentColor")
    static let primaryLight = Color.primary.opacity(0.8)
    static let primaryDark = Color.primary.opacity(1.2)
    
    // Premium Color Palette
    static let background = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    // Glassmorphism Colors
    static let glassBackground = Color.white.opacity(0.1)
    static let glassStroke = Color.white.opacity(0.2)
    static let glassShadow = Color.black.opacity(0.1)
    
    // Habit Type Colors
    static let buildHabit = Color.green
    static let quitHabit = Color.red
    static let buildHabitLight = Color.green.opacity(0.8)
    static let quitHabitLight = Color.red.opacity(0.8)
    
    // Status Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
}

// MARK: - Typography
extension Font {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body.weight(.regular)
    static let callout = Font.callout.weight(.medium)
    static let caption = Font.caption.weight(.regular)
    static let caption2 = Font.caption2.weight(.light)
}

// MARK: - Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
}

// MARK: - Shadows
struct ShadowStyle {
    static let soft = Shadow(color: Color.glassShadow, radius: 10, x: 0, y: 4)
    static let medium = Shadow(color: Color.glassShadow, radius: 20, x: 0, y: 8)
    static let large = Shadow(color: Color.glassShadow, radius: 30, x: 0, y: 12)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Glass Card Style
struct GlassCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadowStyle: Shadow
    
    init(cornerRadius: CGFloat = CornerRadius.lg, shadowStyle: Shadow = ShadowStyle.soft) {
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.glassStroke, lineWidth: 1)
                    )
                    .shadow(
                        color: shadowStyle.color,
                        radius: shadowStyle.radius,
                        x: shadowStyle.x,
                        y: shadowStyle.y
                    )
            )
    }
}

// MARK: - Gradient Button Style
struct GradientButtonStyle: ButtonStyle {
    let colors: [Color]
    let cornerRadius: CGFloat
    let isDisabled: Bool
    
    init(colors: [Color], cornerRadius: CGFloat = CornerRadius.md, isDisabled: Bool = false) {
        self.colors = colors
        self.cornerRadius = cornerRadius
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: isDisabled ? [Color.gray.opacity(0.6)] : colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: configuration.isPressed ? 2 : 8,
                        x: 0,
                        y: configuration.isPressed ? 1 : 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

// MARK: - Habit Type Button Style
struct HabitTypeButtonStyle: ButtonStyle {
    let habitType: HabitType
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isSelected ? .white : .primary)
            .font(.headline)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .fill(
                        isSelected ? 
                        (habitType == .build ? Color.buildHabit : Color.quitHabit) : 
                        Color.secondaryBackground
                    )
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: configuration.isPressed ? 2 : 6,
                        x: 0,
                        y: configuration.isPressed ? 1 : 3
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Streak Counter Style
struct StreakCounterView: View {
    let count: Int
    let type: HabitType
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.caption)
                .foregroundColor(type == .build ? .buildHabit : .quitHabit)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm)
                .fill(Color.tertiaryBackground)
        )
    }
}

// MARK: - Loading State
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            
            Text("Loading...")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Color.glassBackground)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.glassStroke, lineWidth: 1)
                )
        )
        .shadow(color: Color.glassShadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let action: (() -> Void)?
    
    init(title: String, message: String, systemImage: String, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button("Get Started") {
                    action()
                }
                .buttonStyle(GradientButtonStyle(colors: [.primary, .primaryLight]))
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(cornerRadius: CGFloat = CornerRadius.lg, shadowStyle: Shadow = ShadowStyle.soft) -> some View {
        self.modifier(GlassCardStyle(cornerRadius: cornerRadius, shadowStyle: shadowStyle))
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    func responsiveFont(_ font: Font, maxSize: CGFloat? = nil) -> some View {
        self.font(font)
            .minimumScaleFactor(0.8)
            .lineLimit(1)
    }
    
    func adaptiveLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        GeometryReader { geometry in
            if geometry.size.width > 600 {
                // iPad or large screen layout
                content()
                    .padding(.horizontal, Spacing.xl)
            } else {
                // iPhone layout
                content()
                    .padding(.horizontal, Spacing.md)
            }
        }
    }
}

// MARK: - Device Size Classes
extension View {
    @ViewBuilder
    func compactLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            content()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func regularLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content()
        } else {
            self
        }
    }
}

// MARK: - Adaptive Grid
struct AdaptiveGrid<Content: View>: View {
    let content: Content
    let minItemWidth: CGFloat
    let spacing: CGFloat
    
    init(minItemWidth: CGFloat = 150, spacing: CGFloat = Spacing.md, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.minItemWidth = minItemWidth
        self.spacing = spacing
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (spacing * 2)
            let itemsPerRow = max(1, Int(availableWidth / minItemWidth))
            let itemWidth = (availableWidth - (CGFloat(itemsPerRow - 1) * spacing)) / CGFloat(itemsPerRow)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: itemsPerRow),
                spacing: spacing
            ) {
                content
            }
        }
    }
} 