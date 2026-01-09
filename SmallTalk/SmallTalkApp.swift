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

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
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
