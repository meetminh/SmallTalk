import SwiftUI
import Carbon
import CoreServices

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) var openWindow
    @State private var isRecordingHotkey = false
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SmallTalk")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    if appState.state.isRecording {
                        Circle()
                            .stroke(statusColor.opacity(0.5), lineWidth: 2)
                            .frame(width: 32, height: 32)
                            .scaleEffect(pulse ? 1.2 : 1.0)
                            .opacity(pulse ? 0 : 1)
                            .onAppear {
                                withAnimation(Animation.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
                                    pulse = true
                                }
                            }
                    }
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Middle section: Recent Transcript
            if !appState.lastTranscript.isEmpty || appState.state.isProcessing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LATEST TRANSCRIPT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(appState.state.isProcessing ? "Processing audio..." : appState.lastTranscript)
                            .font(.system(size: 13, design: .rounded))
                            .lineSpacing(4)
                            .foregroundColor(appState.state.isProcessing ? .secondary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .italic(appState.state.isProcessing)
                    }
                    .frame(height: 80)
                }
                .padding(16)
                .background(Color.primary.opacity(0.03))
                
                Divider()
            }
            
            // Bottom Section: Controls
            VStack(spacing: 12) {
                // Hotkey Row
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundColor(.secondary)
                    Text("Shortcut")
                        .font(.system(size: 12))
                    Spacer()
                    Button(action: { isRecordingHotkey.toggle() }) {
                        Text(isRecordingHotkey ? "Press keys..." : hotkeyString)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .buttonStyle(HotkeyButtonStyle(isRecording: isRecordingHotkey))
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        openWindow(id: "onboarding")
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }) {
                        Label("Permissions", systemImage: "lock.shield")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(ControlButtonStyle())
                    
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Label("Quit", systemImage: "power")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(ControlButtonStyle())
                }
            }
            .padding(16)
        }
        .frame(width: 280)
        .onAppear {
            setupEventMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            // When the app is activated (e.g. clicking the Dock icon)
            // Show onboarding ONLY if permissions are still missing.
            if !appState.allPermissionsGranted {
                openWindow(id: "onboarding")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
    
    // ... helper methods (hotkeyString, setupEventMonitor, keyName, colors) remain below
    
    private var statusIcon: String {
        switch appState.state {
        case .loadingModel: return "arrow.down.circle"
        case .idle: return "waveform"
        case .recording: return "mic.fill"
        case .processing: return "ellipsis"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    private var statusColor: Color {
        switch appState.state {
        case .loadingModel: return .purple
        case .idle: return .blue
        case .recording: return .red
        case .processing: return .orange
        case .error: return .gray
        }
    }
    
    private var statusText: String {
        switch appState.state {
        case .loadingModel: return "Downloading AI model..."
        case .idle: return "Ready to record"
        case .recording: return "Recording your thoughts..."
        case .processing: return "Transcribing locally..."
        case .error(let msg): return msg
        }
    }
    
    private var hotkeyString: String {
        let mods = appState.hotkeyModifiers
        var str = ""
        if (mods & UInt32(controlKey)) != 0 { str += "⌃" }
        if (mods & UInt32(optionKey)) != 0 { str += "⌥" }
        if (mods & UInt32(shiftKey)) != 0 { str += "⇧" }
        if (mods & UInt32(cmdKey)) != 0 { str += "⌘" }
        str += keyName(for: appState.hotkeyCode)
        return str
    }
    
    private func setupEventMonitor() {
        // Remove any existing monitor just in case
        if let existing = localMonitor {
            NSEvent.removeMonitor(existing)
            localMonitor = nil
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if isRecordingHotkey {
                let modifiers = event.modifierFlags
                var carbonModifiers: UInt32 = 0
                if modifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
                if modifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
                if modifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
                if modifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
                
                appState.updateHotkey(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
                isRecordingHotkey = false
                
                // Remove monitor after we're done
                if let monitor = localMonitor {
                    NSEvent.removeMonitor(monitor)
                    localMonitor = nil
                }
                return nil
            }
            return event
        }
    }
    
    @State private var localMonitor: Any?
    
    private func keyName(for keyCode: UInt32) -> String {
        // Special cases for better UX
        switch keyCode {
        case 36: return "RETURN"
        case 48: return "TAB"
        case 49: return "SPACE"
        case 51: return "DELETE"
        case 53: return "ESC"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: break
        }

        if let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true) {
            if let nsEvent = NSEvent(cgEvent: event) {
                if let chars = nsEvent.charactersIgnoringModifiers, !chars.isEmpty {
                    return chars.uppercased()
                }
            }
        }
        return "K\(keyCode)"
    }
}

// MARK: - Premium Button Style
struct ControlButtonStyle: ButtonStyle {
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.primary.opacity(0.1) : Color.primary.opacity(0.05))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isHovering)
            .animation(.interactiveSpring(), value: configuration.isPressed)
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

struct HotkeyButtonStyle: ButtonStyle {
    let isRecording: Bool
    @State private var isHovering = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecording ? Color.accentColor : (isHovering ? Color.primary.opacity(0.15) : Color.primary.opacity(0.1)))
            )
            .foregroundColor(isRecording ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.interactiveSpring(), value: isHovering)
            .animation(.interactiveSpring(), value: configuration.isPressed)
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}

extension RecordingState {
    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
    
    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
}
