import Foundation
import FluidAudio

class AsrService {
    private var manager: AsrManager?
    
    init() {}
    
    func setup() async throws {
        // AsrManager is the main class for batch processing
        let asr = AsrManager()
        // Download and load the latest v3 models (multilingual parakeet)
        let models = try await AsrModels.downloadAndLoad(version: .v3)
        try await asr.initialize(models: models)
        self.manager = asr
    }
    
    func transcribe(audioBuffer: [Float]) async throws -> String {
        if manager == nil {
            try await setup()
        }
        
        guard let manager = manager else {
            throw NSError(domain: "AsrService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize ASR"])
        }
        
        // FluidAudio expects [Float] at 16kHz mono
        let result = try await manager.transcribe(audioBuffer, source: .microphone)
        return result.text
    }
}
