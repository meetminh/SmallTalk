import SwiftUI
import AVFoundation
import Carbon
import Combine

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                
                Text("Welcome to SmallTalk")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("Let's get you set up in seconds.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            
            // Steps
            VStack(alignment: .leading, spacing: 20) {
                // Step 1: Microphone
                HStack {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 18))
                        .frame(width: 30)
                        .foregroundColor(micAuthorized ? .green : .primary)
                    
                    VStack(alignment: .leading) {
                        Text("Microphone Access")
                            .font(.headline)
                        Text("To hear and transcribe your voice.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if micAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Grant") {
                            requestMic()
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
                .cornerRadius(12)
                
                // Step 2: Accessibility
                HStack {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 18))
                        .frame(width: 30)
                        .foregroundColor(accessibilityAuthorized ? .green : .primary)
                    
                    VStack(alignment: .leading) {
                        Text("Accessibility Access")
                            .font(.headline)
                        Text("To paste text instantly into your apps.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if accessibilityAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Grant") {
                            openAccessibilitySettings()
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Footer
            Button(action: {
                completeSetup()
            }) {
                Text(allReady ? "Start Using SmallTalk" : "Finish Setup")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(allReady ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(!allReady)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .frame(width: 400, height: 550)
        .background(EffectView(material: .hudWindow, blendingMode: .behindWindow))
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
