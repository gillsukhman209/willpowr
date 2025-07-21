import SwiftUI

// MARK: - Morphing Geometric Shape
struct MorphingShape: View {
    @State private var morphProgress: CGFloat = 0
    @State private var rotation: Double = 0
    let color: Color
    let size: CGFloat
    
    init(color: Color = DesignTokens.Colors.electricBlue, size: CGFloat = 200) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Base shape that morphs
            MorphingGeometry(progress: morphProgress)
                .fill(color.opacity(0.1))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
                .glow(color: color, radius: 30)
            
            // Inner shape with different morph timing
            MorphingGeometry(progress: morphProgress + 0.3)
                .fill(color.opacity(0.2))
                .frame(width: size * 0.6, height: size * 0.6)
                .rotationEffect(.degrees(-rotation * 1.5))
        }
        .onAppear {
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                morphProgress = 1
                rotation = 360
            }
        }
    }
}

// MARK: - Custom Shape that Morphs
struct MorphingGeometry: Shape {
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let adjustedProgress = progress.truncatingRemainder(dividingBy: 1)
        
        if adjustedProgress < 0.25 {
            // Square to rounded square
            let cornerRadius = rect.width * 0.3 * (adjustedProgress * 4)
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        } else if adjustedProgress < 0.5 {
            // Rounded square to circle
            let localProgress = (adjustedProgress - 0.25) * 4
            let cornerRadius = rect.width * (0.3 + 0.2 * localProgress)
            return RoundedRectangle(cornerRadius: cornerRadius).path(in: rect)
        } else if adjustedProgress < 0.75 {
            // Circle to triangle
            let localProgress = (adjustedProgress - 0.5) * 4
            return morphCircleToTriangle(in: rect, progress: localProgress)
        } else {
            // Triangle back to square
            let localProgress = (adjustedProgress - 0.75) * 4
            return morphTriangleToSquare(in: rect, progress: localProgress)
        }
    }
    
    private func morphCircleToTriangle(in rect: CGRect, progress: CGFloat) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        // Three points for triangle
        let top = CGPoint(x: center.x, y: center.y - radius)
        let bottomLeft = CGPoint(x: center.x - radius * 0.866, y: center.y + radius * 0.5)
        let bottomRight = CGPoint(x: center.x + radius * 0.866, y: center.y + radius * 0.5)
        
        if progress < 0.5 {
            // Still mostly circle
            path.addArc(center: center, radius: radius, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
        } else {
            // Morph to triangle
            path.move(to: top)
            path.addLine(to: bottomLeft)
            path.addLine(to: bottomRight)
            path.closeSubpath()
        }
        
        return path
    }
    
    private func morphTriangleToSquare(in rect: CGRect, progress: CGFloat) -> Path {
        var path = Path()
        let inset = rect.width * 0.1
        let squareRect = rect.insetBy(dx: inset, dy: inset)
        
        // Interpolate between triangle and square
        let topLeft = CGPoint(x: squareRect.minX, y: squareRect.minY)
        let topRight = CGPoint(x: squareRect.maxX, y: squareRect.minY)
        let bottomLeft = CGPoint(x: squareRect.minX, y: squareRect.maxY)
        let bottomRight = CGPoint(x: squareRect.maxX, y: squareRect.maxY)
        
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Floating Particle System
struct ParticleSystem: View {
    @State private var particles: [Particle] = []
    let particleCount = 20
    let color: Color
    
    init(color: Color = DesignTokens.Colors.neonGreen) {
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .glow(color: color, radius: 10)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.3...0.8),
                velocity: CGPoint(
                    x: CGFloat.random(in: -30...30),
                    y: CGFloat.random(in: -50 ... -20)
                )
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x * 0.016
                particles[i].position.y += particles[i].velocity.y * 0.016
                
                // Reset particle if it goes off screen
                if particles[i].position.y < -20 {
                    particles[i].position.y = UIScreen.main.bounds.height + 20
                    particles[i].position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                }
            }
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var velocity: CGPoint
}

// MARK: - Liquid Transition
struct LiquidTransition: ViewModifier {
    let isActive: Bool
    @State private var offset: CGFloat = 0
    @State private var wavePhase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geometry in
                    if isActive {
                        LiquidMask(
                            progress: offset / geometry.size.height,
                            wavePhase: wavePhase
                        )
                        .fill(Color.black)
                    } else {
                        Rectangle()
                            .fill(Color.black)
                    }
                }
            )
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        offset = UIScreen.main.bounds.height
                    }
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        wavePhase = .pi * 2
                    }
                }
            }
    }
}

// MARK: - Liquid Mask Shape
struct LiquidMask: Shape {
    var progress: CGFloat
    var wavePhase: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, wavePhase) }
        set {
            progress = newValue.first
            wavePhase = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 20
        let yOffset = rect.height * (1 - progress)
        
        path.move(to: CGPoint(x: 0, y: yOffset))
        
        // Create wave pattern
        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / rect.width
            let sine = sin((relativeX + wavePhase) * .pi * 4)
            let y = yOffset + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Complete the mask
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - View Extension for Liquid Transition
extension View {
    func liquidTransition(isActive: Bool) -> some View {
        self.modifier(LiquidTransition(isActive: isActive))
    }
}
