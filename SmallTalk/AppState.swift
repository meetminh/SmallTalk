import Foundation
import SwiftUI
import Combine
import Carbon
import AVFoundation

enum RecordingState {
    case loadingModel
    case idle
    case recording
    case processing
    case error(String)
}

@MainActor
class AppState: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var lastTranscript: String = ""
    @Published var hotkeyCode: UInt32 = UserDefaults.standard.object(forKey: "hotkeyCode") as? UInt32 ?? 1 // 'S'
    @Published var hotkeyModifiers: UInt32 = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? UInt32 ?? UInt32(controlKey | cmdKey)
    @Published var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    private let audioService = AudioCaptureService()
    private let asrService = AsrService()
    private let pasteService = PasteService()
    private let hotkeyService = HotkeyService()
    
    init() {
        checkAccessibilityPermissions()
        setupHotkey()
        prewarmAsr()
    }
    
    private func checkAccessibilityPermissions() {
        let options = ["AXTrustedCheckOptionPrompt": false] as CFDictionary
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        print("AppState: Accessibility permissions granted: \(accessibilityEnabled)")
        if !accessibilityEnabled {
            print("AppState: WARNING - Accessibility permissions are REQUIRED for global hotkeys and pasting.")
        }
    }
    
    private func prewarmAsr() {
        state = .loadingModel
        Task {
            do {
                try await asrService.setup()
                state = .idle
            } catch {
                state = .error("Model load failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupHotkey() {
        hotkeyService.onTrigger = { [weak self] in
            Task { @MainActor in
                await self?.toggleRecording()
            }
        }
        hotkeyService.registerHotkey(keyCode: hotkeyCode, modifiers: hotkeyModifiers)
    }
    
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        self.hotkeyCode = keyCode
        self.hotkeyModifiers = modifiers
        UserDefaults.standard.set(keyCode, forKey: "hotkeyCode")
        UserDefaults.standard.set(modifiers, forKey: "hotkeyModifiers")
        hotkeyService.registerHotkey(keyCode: keyCode, modifiers: modifiers)
    }
    
    func toggleRecording() async {
        print("AppState: [TOGGLE] Current state: \(state)")
        
        switch state {
        case .idle, .error:
            print("AppState: [TOGGLE] Starting recording...")
            await startRecording()
        case .recording:
            print("AppState: [TOGGLE] Stopping and transcribing...")
            await stopAndTranscribe()
        case .loadingModel, .processing:
            print("AppState: [TOGGLE] Ignoring - model loading or processing")
            break
        }
    }
    
    private func startRecording() async {
        do {
            try await audioService.startRecording()
            state = .recording
        } catch {
            state = .error("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopAndTranscribe() async {
        state = .processing
        
        let buffer = await audioService.stopRecording()
        
        do {
            let transcript = try await asrService.transcribe(audioBuffer: buffer)
            self.lastTranscript = transcript
            
            if !transcript.isEmpty {
                pasteService.paste(text: transcript)
                state = .idle
            } else {
                state = .idle // Or maybe .error("Empty transcript")
            }
        } catch {
            state = .error("Transcription failed: \(error.localizedDescription)")
        }
    }
    
    func requestPermissions() {
        print("AppState: [PERMISSION] Requesting Microphone and Accessibility...")
        
        // Request Microphone
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            print("AppState: [PERMISSION] Microphone granted: \(granted)")
        }
        
        // Accessibility permissions check
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        print("AppState: [PERMISSION] Accessibility granted: \(accessibilityEnabled)")
    }
}
