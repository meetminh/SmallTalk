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
        // Force the app to show in the Dock so the new icon is visible
        NSApplication.shared.setActivationPolicy(.regular)
    }

    @Environment(\.openWindow) var openWindow
    
    var body: some Scene {
        WindowGroup(id: "onboarding") {
            OnboardingView(appState: appState)
                .onDisappear {
                    if appState.hasCompletedOnboarding {
                        print("SmallTalkApp: Onboarding complete.")
                    }
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra {
            MenuBarView(appState: appState)
                .onAppear {
                    // Check if we need to show onboarding
                    if !appState.hasCompletedOnboarding {
                        // Small delay to ensure window system is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            openWindow(id: "onboarding")
                            NSApplication.shared.activate(ignoringOtherApps: true)
                        }
                    }
                }
        } label: {
            Image(systemName: recordingIcon)
        }
        .menuBarExtraStyle(.window)
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
