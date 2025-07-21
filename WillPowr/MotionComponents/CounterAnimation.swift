import SwiftUI

// MARK: - Animated Number Counter
struct AnimatedCounter: View {
    let value: Int
    let fontSize: CGFloat
    let color: Color
    let duration: Double
    
    @State private var displayValue: Int = 0
    
    init(
        value: Int,
        fontSize: CGFloat = DesignTokens.Typography.giantTitle,
        color: Color = DesignTokens.Colors.offWhite,
        duration: Double = 1.0
    ) {
        self.value = value
        self.fontSize = fontSize
        self.color = color
        self.duration = duration
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(digits, id: \.offset) { digit in
                DigitView(
                    digit: digit.element,
                    fontSize: fontSize,
                    color: color
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .id("\(digit.offset)-\(digit.element)")
            }
        }
        .onChange(of: value) { _, newValue in
            animateToValue(newValue)
        }
        .onAppear {
            displayValue = value
        }
    }
    
    private var digits: [(offset: Int, element: Character)] {
        Array(String(displayValue).enumerated())
    }
    
    private func animateToValue(_ target: Int) {
        let startValue = displayValue
        let difference = target - startValue
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    displayValue = startValue + (difference * (i + 1)) / steps
                }
            }
        }
        
        // Ensure we hit the exact target
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                displayValue = target
            }
        }
    }
}

// MARK: - Individual Digit View
struct DigitView: View {
    let digit: Character
    let fontSize: CGFloat
    let color: Color
    
    var body: some View {
        Text(String(digit))
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundColor(color)
            .monospacedDigit()
    }
}

// MARK: - Progress Ring with Counter
struct AnimatedProgressRing: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let primaryColor: Color
    let secondaryColor: Color
    
    @State private var animatedProgress: Double = 0
    @State private var rotation: Double = -90
    
    init(
        progress: Double,
        size: CGFloat = 200,
        lineWidth: CGFloat = 20,
        primaryColor: Color = DesignTokens.Colors.neonGreen,
        secondaryColor: Color = DesignTokens.Colors.lightGray
    ) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(secondaryColor, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    primaryColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .glow(color: primaryColor, radius: 10)
            
            // Center content
            VStack(spacing: DesignTokens.Spacing.small) {
                AnimatedCounter(
                    value: Int(animatedProgress * 100),
                    fontSize: DesignTokens.Typography.largeTitle,
                    color: primaryColor
                )
                
                Text("%")
                    .font(.system(size: DesignTokens.Typography.headline, weight: .bold))
                    .foregroundColor(primaryColor.opacity(0.8))
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                animatedProgress = progress
            }
            
            // Subtle rotation animation
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                rotation = 270
            }
        }
    }
}

// MARK: - Streak Fire Animation
struct StreakFireAnimation: View {
    let streakCount: Int
    @State private var flameOffset: CGFloat = 0
    @State private var flameScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Multiple flame layers for depth
            ForEach(0..<3) { i in
                Image(systemName: "flame.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(flameColor(for: i))
                    .scaleEffect(flameScale - CGFloat(i) * 0.1)
                    .offset(y: flameOffset + CGFloat(i) * 2)
                    .blur(radius: CGFloat(i) * 0.5)
            }
            
            // Streak number
            Text("\(streakCount)")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(DesignTokens.Colors.offWhite)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .glow(color: DesignTokens.Colors.hotPink, radius: 20)
        .onAppear {
            // Flame flicker animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                flameOffset = -5
                flameScale = 1.1
            }
        }
    }
    
    private func flameColor(for layer: Int) -> Color {
        switch layer {
        case 0: return DesignTokens.Colors.hotPink
        case 1: return DesignTokens.Colors.warningOrange
        default: return DesignTokens.Colors.neonGreen
        }
    }
}

// MARK: - Success Celebration
struct SuccessCelebration: View {
    @State private var particles: [CelebrationParticle] = []
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 1
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Success checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100, weight: .bold))
                .foregroundColor(DesignTokens.Colors.neonGreen)
                .scaleEffect(scale)
                .glow(color: DesignTokens.Colors.neonGreen, radius: 40)
            
            // Particle explosion
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(particle.offset)
                    .opacity(particle.opacity)
            }
        }
        .opacity(opacity)
        .onAppear {
            celebrate()
        }
    }
    
    private func celebrate() {
        // Generate particles
        particles = (0..<20).map { _ in
            CelebrationParticle(
                color: [DesignTokens.Colors.neonGreen, DesignTokens.Colors.electricBlue, DesignTokens.Colors.hotPink].randomElement()!,
                size: CGFloat.random(in: 4...12),
                offset: .zero,
                targetOffset: CGSize(
                    width: CGFloat.random(in: -150...150),
                    height: CGFloat.random(in: -150...150)
                ),
                opacity: 1
            )
        }
        
        // Animate checkmark
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.2
        }
        
        withAnimation(.easeOut(duration: 0.2).delay(0.3)) {
            scale = 1.0
        }
        
        // Animate particles
        for i in particles.indices {
            withAnimation(.easeOut(duration: 0.8)) {
                particles[i].offset = particles[i].targetOffset
                particles[i].opacity = 0
            }
        }
        
        // Fade out
        withAnimation(.easeOut(duration: 0.3).delay(1.0)) {
            opacity = 0
        }
        
        // Callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete()
        }
    }
}

// MARK: - Celebration Particle Model
struct CelebrationParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var offset: CGSize
    let targetOffset: CGSize
    var opacity: Double
}