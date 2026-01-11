import SwiftUI
import AVFoundation
import Carbon
import Combine

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            EffectView(material: .hudWindow, blendingMode: .behindWindow)
                .overlay(Color.black.opacity(0.4))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 20) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to SmallTalk")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .tracking(-0.5)
                        
                        Text("Let's get you set up in seconds.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 48)
                .padding(.bottom, 40)
                
                // Steps
                VStack(spacing: 16) {
                    PermissionCard(
                        title: "Microphone Access",
                        subtitle: "To hear and transcribe your voice.",
                        icon: "mic.fill",
                        isAuthorized: micAuthorized,
                        action: requestMic
                    )
                    
                    PermissionCard(
                        title: "Accessibility Access",
                        subtitle: "To paste text instantly into your apps.",
                        icon: "keyboard.fill",
                        isAuthorized: accessibilityAuthorized,
                        action: openAccessibilitySettings
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer
                VStack(spacing: 16) {
                    Button(action: {
                        completeSetup()
                    }) {
                        Text(allReady ? "Start Creating" : "Finish Setup")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(allReady ? Color.white : Color.white.opacity(0.1))
                            .foregroundColor(allReady ? .black : .white.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!allReady)
                    
                    if !allReady {
                        Text("Permissions required to continue")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .frame(width: 400, height: 620)
        .onAppear {
            checkPermissions()
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            checkPermissions()
        }
    }
    
    // MARK: - Logic
    @State private var micAuthorized = false
    @State private var accessibilityAuthorized = false
    
    var allReady: Bool {
        micAuthorized && accessibilityAuthorized
    }
    
    private func checkPermissions() {
        // Mic
        micAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        // Accessibility
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

// MARK: - Components
struct PermissionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isAuthorized: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isAuthorized ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isAuthorized ? .green : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                    .symbolRenderingMode(.hierarchical)
            } else {
                Button(action: action) {
                    Text("Grant")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isAuthorized ? Color.green.opacity(0.3) : Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: isAuthorized ? [] : [4, 4]))
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isAuthorized ? Color.green.opacity(0.05) : Color.black.opacity(0.2))
        )
    }
}

struct EffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
