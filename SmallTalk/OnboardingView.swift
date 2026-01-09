import SwiftUI
import AVFoundation
import Carbon
import Combine

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background Blur & Vibrancy
            EffectView(material: .fullScreenUI, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            // Subtle Gradient Overlay for Contrast
            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero Section
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)

                        Image(systemName: "waveform.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .symbolEffect(.pulse.byLayer, options: .repeating)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Welcome to SmallTalk")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("The faster, more private way to capture thoughts.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 60)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 50)
                
                // Content Section
                VStack(spacing: 20) {
                    PermissionRow(
                        isGranted: micAuthorized,
                        icon: "mic.fill",
                        color: .blue,
                        title: "Microphone Access",
                        description: "Process your voice securely and privately on this Mac.",
                        action: requestMic
                    )
                    
                    PermissionRow(
                        isGranted: accessibilityAuthorized,
                        icon: "keyboard.fill",
                        color: .purple,
                        title: "Accessibility Access",
                        description: "Paste your ideas instantly into any app you use.",
                        action: openAccessibilitySettings
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Footer Section
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 32)
                        .opacity(0.5)

                    Button(action: completeSetup) {
                        HStack {
                            Text(allReady ? "Get Started" : "Finish Setup")
                            if allReady {
                                Image(systemName: "arrow.right")
                            }
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .disabled(!allReady)
                    .keyboardShortcut(.defaultAction)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .shadow(color: .blue.opacity(allReady ? 0.3 : 0), radius: 10, x: 0, y: 5)
                }
                .background(
                    EffectView(material: .headerView, blendingMode: .withinWindow)
                        .opacity(0.2)
                        .ignoresSafeArea()
                )
            }
        }
        .frame(width: 500, height: 600)
        .onAppear(perform: checkPermissions)
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            checkPermissions()
        }
    }
    
    // Logic
    @State private var micAuthorized = false
    @State private var accessibilityAuthorized = false
    
    var allReady: Bool { micAuthorized && accessibilityAuthorized }
    
    private func checkPermissions() {
        micAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        accessibilityAuthorized = AXIsProcessTrustedWithOptions(options)
    }
    
    private func requestMic() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { self.micAuthorized = granted }
        }
    }
    
    private func openAccessibilitySettings() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let _ = AXIsProcessTrustedWithOptions(options)
    }
    
    private func completeSetup() {
        withAnimation {
            appState.hasCompletedOnboarding = true
        }
        dismiss()
    }
}

struct PermissionRow: View {
    let isGranted: Bool
    let icon: String
    let color: Color
    let title: String
    let description: String
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 20) {
            // Visual Indicator
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green.opacity(0.15) : color.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: isGranted ? "checkmark" : icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isGranted ? .green : color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            if !isGranted {
                Button(action: action) {
                    Text("Enable")
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(color)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, value: isGranted)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1.5)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
