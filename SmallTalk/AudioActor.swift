import Foundation
import AVFoundation

actor AudioActor {
    private var engine: AVAudioEngine?
    private var rawBuffer: [Float] = []
    private var hardwareSampleRate: Double = 48000
    
    var isRecording: Bool {
        return engine?.isRunning ?? false
    }
    
    func start() async throws {
        print("AudioActor: [START] Preparing engine on background thread...")
        
        // 1. Clean up old engine
        cleanup()
        
        // 2. Create fresh engine
        let newEngine = AVAudioEngine()
        let inputNode = newEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        self.hardwareSampleRate = format.sampleRate
        self.engine = newEngine
        
        print("AudioActor: [HARDWARE] Rate: \(format.sampleRate), Ch: \(format.channelCount)")
        
        // 3. Reset Buffer
        rawBuffer.removeAll(keepingCapacity: false)
        rawBuffer.reserveCapacity(Int(format.sampleRate * 60)) // Reserve 1 min
        
        // 4. Install Tap NOT on Main Thread
        // Note: The tap block itself runs on an internal audio thread, but we communicate
        // back to the actor via async tasks if needed, or simply append since we are inside the actor? 
        // ACTUALLY: The tap block is a C-function pointer effectively. 
        // We cannot access 'self' (actor) synchronously from the tap block without `nonisolated`.
        // To be safe and high-perf, we will use a locked helper class OR unsafe pointers, 
        // BUT simpler: Use a `@Sendable` closure that captures a safe-to-append buffer container.
        // HOWEVER, actors protect state. Accessing 'self.rawBuffer' from tap block is async.
        // FOR HIGH PERF AUDIO: We often use a helper class `AudioBuffer` that is `@unchecked Sendable` acting as a minimal lock wrapper.
        
        // Let's use the simplest robust pattern: A small non-actor helper class for the buffer.
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            // We must act quickly. Ideally we don't await. 
            // Valid pattern: Spin up a Task to append data to the actor.
            // This guarantees thread safety at the cost of slight overhead.
            
            if let channelData = buffer.floatChannelData?[0] {
                let count = Int(buffer.frameLength)
                let data = Array(UnsafeBufferPointer(start: channelData, count: count))
                
                Task {
                    await self.appendData(data)
                }
            }
        }
        
        newEngine.prepare()
        try newEngine.start()
        print("AudioActor: [SUCCESS] Recording started.")
    }
    
    func appendData(_ data: [Float]) {
        rawBuffer.append(contentsOf: data)
    }
    
    func stop() async -> [Float] {
        print("AudioActor: [STOP] Stopping engine...")
        
        if let currentEngine = engine {
            currentEngine.stop()
            currentEngine.inputNode.removeTap(onBus: 0)
        }
        engine = nil
        
        let captured = rawBuffer
        rawBuffer.removeAll(keepingCapacity: false)
        
        print("AudioActor: [DATA] Captured \(captured.count) samples")
        
        if captured.isEmpty { return [] }
        
        return resample(captured, from: hardwareSampleRate, to: 16000)
    }
    
    // Internal Cleanup
    private func cleanup() {
        if let old = engine {
            old.stop()
            old.inputNode.removeTap(onBus: 0)
        }
        engine = nil
    }
    
    // Pure computation - safe to run on actor
    private func resample(_ samples: [Float], from sourceRate: Double, to targetRate: Double) -> [Float] {
        if sourceRate == targetRate { return samples }
        
        print("AudioActor: [RESAMPLE] \(sourceRate) -> \(targetRate)")
        
        guard let srcFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sourceRate, channels: 1, interleaved: false),
              let dstFmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: targetRate, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: srcFmt, to: dstFmt) else {
            return samples
        }
        
        let ratio = targetRate / sourceRate
        let outLength = Int(Double(samples.count) * ratio)
        
        guard let srcBuf = AVAudioPCMBuffer(pcmFormat: srcFmt, frameCapacity: AVAudioFrameCount(samples.count)),
              let dstBuf = AVAudioPCMBuffer(pcmFormat: dstFmt, frameCapacity: AVAudioFrameCount(outLength)) else {
            return samples
        }
        
        srcBuf.frameLength = AVAudioFrameCount(samples.count)
        if let srcData = srcBuf.floatChannelData?[0] {
            samples.withUnsafeBufferPointer { ptr in
                srcData.update(from: ptr.baseAddress!, count: samples.count)
            }
        }
        
        var error: NSError?
        nonisolated(unsafe) let unsafeSrcBuf = srcBuf
        converter.convert(to: dstBuf, error: &error) { _, status in
            status.pointee = .haveData
            return unsafeSrcBuf
        }
        
        if let dstData = dstBuf.floatChannelData?[0] {
            return Array(UnsafeBufferPointer(start: dstData, count: Int(dstBuf.frameLength)))
        }
        return []
    }
}
