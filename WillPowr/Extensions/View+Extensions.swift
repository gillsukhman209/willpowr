import SwiftUI

extension View {
    // MARK: - Glassmorphism Effects
    
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.glassGradient)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.glassBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.glassShadow, radius: 10, x: 0, y: 4)
            )
    }
    
    func premiumCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.fallbackGlassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.fallbackGlassBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.fallbackGlassShadow, radius: 10, x: 0, y: 4)
            )
    }
    
    func glassButton(isPressed: Bool = false) -> some View {
        self
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassGradient)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.glassBorder, lineWidth: 0.5)
                    )
                    .shadow(color: Color.glassShadow, radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
            )
            .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
    
    // MARK: - Premium Animations
    
    func smoothSlideIn(delay: Double = 0) -> some View {
        self
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: true)
    }
    
    func bounceScale(trigger: Bool) -> some View {
        self
            .scaleEffect(trigger ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: trigger)
    }
    
    func pulseEffect(isActive: Bool) -> some View {
        self
            .scaleEffect(isActive ? 1.02 : 1.0)
            .opacity(isActive ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)
    }
    
    // MARK: - Responsive Layout
    
    func responsivePadding() -> some View {
        self.padding(.horizontal, screenWidth < 400 ? 16 : 20)
    }
    
    func responsiveCornerRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: screenWidth < 400 ? 12 : 16))
    }
    
    // MARK: - Gradient Backgrounds
    
    func buildHabitGradient() -> some View {
        self.background(Color.buildHabitGradient)
    }
    
    func quitHabitGradient() -> some View {
        self.background(Color.quitHabitGradient)
    }
    
    func backgroundGradient() -> some View {
        self.background(Color.backgroundGradient)
    }
    
    // MARK: - Haptic Feedback
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Conditional Modifiers
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    // MARK: - Safe Area Handling
    
    func safeAreaPadding() -> some View {
        self.padding(.top, safeAreaInsets.top)
            .padding(.bottom, safeAreaInsets.bottom)
            .padding(.leading, safeAreaInsets.left)
            .padding(.trailing, safeAreaInsets.right)
    }
}

// MARK: - Screen Dimensions

extension View {
    var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    var safeAreaInsets: UIEdgeInsets {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIEdgeInsets.zero
        }
        return window.safeAreaInsets
    }
}

// MARK: - Custom Button Style

struct PremiumButtonStyle: ButtonStyle {
    let color: Color
    let fullWidth: Bool
    
    init(color: Color = .accent, fullWidth: Bool = false) {
        self.color = color
        self.fullWidth = fullWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 2 : 8, x: 0, y: configuration.isPressed ? 1 : 4)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Premium Text Field Style

struct PremiumTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Custom Card Style

struct PremiumCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Bool
    
    init(cornerRadius: CGFloat = 16, shadow: Bool = true) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.fallbackGlassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.fallbackGlassBorder, lineWidth: 0.5)
                    )
                    .if(shadow) { view in
                        view.shadow(color: Color.fallbackGlassShadow, radius: 10, x: 0, y: 4)
                    }
            )
    }
}

// MARK: - Keyboard Dismiss

struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                // Dismiss keyboard when tapping anywhere
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    /// Adds tap-to-dismiss keyboard functionality
    func dismissKeyboardOnTap() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
}
