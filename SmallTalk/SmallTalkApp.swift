//
//  SmallTalkApp.swift
//  SmallTalk
//
//  Created by QuangMinh Tran on 08.01.26.
//

import SwiftUI
import SwiftData

@main
struct SmallTalkApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Set to .accessory to hide the Dock icon and behave as a background utility
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    @Environment(\.openWindow) var openWindow
    
    var body: some Scene {
        WindowGroup(id: "onboarding") {
            OnboardingView(appState: appState)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra {
            MenuBarView(appState: appState)
                .onAppear {
                    // Initial check on launch: Show onboarding ONLY if permissions are missing 
                    // and the user hasn't explicitly dismissed it once before.
                    if !appState.allPermissionsGranted && !appState.hasCompletedOnboarding {
                        showOnboarding()
                    }
                }
        } label: {
            Image(systemName: recordingIcon)
        }
        .menuBarExtraStyle(.window)
    }
    
    private func showOnboarding() {
        // Small delay to ensure window system is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            openWindow(id: "onboarding")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    private var recordingIcon: String {
        switch appState.state {
        case .loadingModel: return "arrow.down.circle"
        case .recording: return "mic.fill"
        case .processing: return "sparkles"
        case .error: return "exclamationmark.triangle"
        default: return "waveform"
        }
    }
}
