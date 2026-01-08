import Foundation
import AVFoundation

// Main Actor facade that coordinates with the background AudioActor
@MainActor
class AudioCaptureService {
    private let actor = AudioActor()
    
    // We can check if recording is active by asking the actor asynchronously
    // However, for UI responsiveness, AppState tracks the 'state' variable.
    // This helper might be less useful now, but we'll keep it async.
    func isRecording() async -> Bool {
        return await actor.isRecording
    }
    
    func startRecording() async throws {
        // Checking permissions on Main Actor is fine and fast
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status != .authorized {
            print("AudioCaptureService: [ERROR] Mic not authorized (status: \(status.rawValue))")
            throw NSError(domain: "AudioCaptureService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Microphone access not authorized"])
        }
        
        print("AudioCaptureService: [BRIDGE] Delegating start to Actor...")
        // This 'await' suspends this function, but frees the UI thread!
        try await actor.start()
    }
    
    func stopRecording() async -> [Float] {
        print("AudioCaptureService: [BRIDGE] Delegating stop to Actor...")
        return await actor.stop()
    }
}
