import SwiftUI
import HealthKit

struct PermissionsView: View {
    @EnvironmentObject private var healthKitService: HealthKitService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasShownPermissions") private var hasShownPermissions = false
    
    @State private var isRequestingPermissions = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let permissions = [
        PermissionItem(
            icon: "figure.walk",
            title: "Steps & Activity",
            description: "Track your daily steps and walking distance for movement habits",
            color: .green
        ),
        PermissionItem(
            icon: "heart.fill",
            title: "Exercise & Workouts",
            description: "Monitor exercise minutes and workout sessions automatically",
            color: .red
        ),
        PermissionItem(
            icon: "bed.double.fill",
            title: "Sleep Analysis",
            description: "Track sleep patterns for better sleep habits",
            color: .purple
        ),
        PermissionItem(
            icon: "brain.head.profile",
            title: "Mindfulness",
            description: "Log meditation and mindfulness sessions",
            color: .blue
        )
    ]
    
    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating orbs for depth
            FloatingOrbs()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        // App Icon/Logo
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "flame.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Welcome to WillPowr")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Let's set up your health tracking")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 40)
                    
                    // Tracking Mode Explanation
                    trackingModeExplanation
                    
                    // Permissions Cards
                    VStack(spacing: 16) {
                        ForEach(permissions, id: \.title) { permission in
                            PermissionCard(permission: permission)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Privacy Note
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Your Privacy is Protected")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text("Your health data stays on your device and is never shared with third parties. You can revoke permissions anytime in Settings.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Enable Button
                        Button(action: requestPermissions) {
                            HStack {
                                if isRequestingPermissions {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                }
                                
                                Text(isRequestingPermissions ? "Requesting Permissions..." : "Enable Health Tracking")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 5)
                        }
                        .disabled(isRequestingPermissions)
                        
                        // Skip Button
                        Button(action: skipPermissions) {
                            Text("Skip for Now")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        .background(Color.clear)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Permission Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Actions
    
    private func requestPermissions() {
        guard !isRequestingPermissions else { return }
        
        isRequestingPermissions = true
        
        Task {
            do {
                try await healthKitService.requestPermissions()
                
                await MainActor.run {
                    isRequestingPermissions = false
                    hasShownPermissions = true
                    
                    // Fetch and log all health data for testing
                    Task {
                        await healthKitService.fetchAllHealthData()
                    }
                    
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isRequestingPermissions = false
                    
                    // Even if there was an error, refresh authorization status
                    // in case user actually granted permissions
                    Task {
                        await healthKitService.refreshAuthorizationStatus()
                    }
                    
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func skipPermissions() {
        hasShownPermissions = true
        dismiss()
    }
    
    // MARK: - Tracking Mode Explanation
    
    private var trackingModeExplanation: some View {
        VStack(spacing: 20) {
            Text("Choose Your Tracking Style")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Automatic Tracking Card
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(height: 30)
                    
                    Text("Automatic")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 6) {
                        Text("• HealthKit integration")
                        Text("• Real-time updates")
                        Text("• Steps & exercise tracking")
                        Text("• Requires permissions")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Manual Tracking Card
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                        .frame(height: 30)
                    
                    Text("Manual")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 6) {
                        Text("• Simple tap to complete")
                        Text("• No permissions needed")
                        Text("• Works for any habit")
                        Text("• Full privacy control")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            Text("💡 You can mix automatic and manual habits, and change modes anytime in settings")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Permission Item Model

struct PermissionItem {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Permission Card Component

struct PermissionCard: View {
    let permission: PermissionItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(permission.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: permission.icon)
                    .font(.title2)
                    .foregroundColor(permission.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(permission.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(permission.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    PermissionsView()
        .environmentObject(HealthKitService())
        .preferredColorScheme(.dark)
} 