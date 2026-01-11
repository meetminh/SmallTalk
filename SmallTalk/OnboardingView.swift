import SwiftUI
import AVFoundation
import Carbon
import Combine

// MARK: - Design Tokens (Premium Dark Theme)
private enum DesignTokens {
    static let bgPrimary = Color.black
    static let cardBg = Color(red: 0.11, green: 0.11, blue: 0.118) // #1C1C1E
    static let cardBorder = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
    static let success = Color(red: 0.204, green: 0.78, blue: 0.349) // #34C759
    
    static let cornerRadius: CGFloat = 20
    static let cardPadding: CGFloat = 20
    static let contentPadding: CGFloat = 24
}

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Pure black background
            DesignTokens.bgPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 24) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to SmallTalk")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(-0.5)
                            .foregroundColor(DesignTokens.textPrimary)
                        
                        Text("Let's get you set up in seconds.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                }
                .padding(.top, 56)
                .padding(.bottom, 48)
                
                // Permission Cards
                VStack(spacing: 16) {
                    PermissionCardView(
                        title: "Microphone Access",
                        subtitle: "To hear and transcribe your voice.",
                        icon: "mic.fill",
                        isAuthorized: micAuthorized,
                        action: requestMic
                    )
                    
                    PermissionCardView(
                        title: "Accessibility Access",
                        subtitle: "To paste text instantly into your apps.",
                        icon: "keyboard.fill",
                        isAuthorized: accessibilityAuthorized,
                        action: openAccessibilitySettings
                    )
                }
                .padding(.horizontal, DesignTokens.contentPadding)
                
                Spacer()
                
                // Primary Button (no background card)
                VStack(spacing: 12) {
                    Button(action: completeSetup) {
                        Text(allReady ? "Start Creating" : "Complete Setup")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(allReady ? Color.white : Color.white.opacity(0.08))
                            .foregroundColor(allReady ? .black : .white.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!allReady)
                    
                    if !allReady {
                        Text("Grant permissions above to continue")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DesignTokens.textSecondary.opacity(0.6))
                    }
                }
                .padding(.horizontal, DesignTokens.contentPadding)
                .padding(.bottom, 32)
            }
        }
        .frame(width: 400, height: 580)
        .onAppear {
            checkPermissions()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            checkPermissions()
        }
    }
    
    // MARK: - State & Logic
    @State private var micAuthorized = false
    @State private var accessibilityAuthorized = false
    
    var allReady: Bool {
        micAuthorized && accessibilityAuthorized
    }
    
    private func checkPermissions() {
        micAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        accessibilityAuthorized = AXIsProcessTrustedWithOptions(options)
    }
    
    private func requestMic() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                self.micAuthorized = granted
            }
        }
    }
    
    private func openAccessibilitySettings() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let _ = AXIsProcessTrustedWithOptions(options)
    }
    
    private func completeSetup() {
        appState.hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Permission Card Component
struct PermissionCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let isAuthorized: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(isAuthorized ? DesignTokens.success.opacity(0.15) : DesignTokens.cardBg)
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isAuthorized ? DesignTokens.success : DesignTokens.textSecondary)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DesignTokens.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(DesignTokens.textSecondary)
            }
            
            Spacer()
            
            // Action
            if isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.success)
            } else {
                Button(action: action) {
                    Text("Grant")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignTokens.textPrimary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                .fill(DesignTokens.cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cornerRadius)
                .stroke(
                    isAuthorized ? DesignTokens.success.opacity(0.4) : DesignTokens.cardBorder,
                    style: StrokeStyle(lineWidth: 1, dash: isAuthorized ? [] : [6, 4])
                )
        )
    }
}
