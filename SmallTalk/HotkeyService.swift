import Foundation
import AppKit
import Carbon

class HotkeyService {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    var onTrigger: (() -> Void)?
    
    func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        unregisterHotkey()
        
        print("HotkeyService: [CONFIG] Targeting KeyCode: \(keyCode), Modifiers: \(modifiers)")
        
        let handler: (NSEvent) -> NSEvent? = { [weak self] event in
            let eventKeyCode = UInt32(event.keyCode)
            let eventModifiers = event.modifierFlags
            
            var carbonModifiers: UInt32 = 0
            if eventModifiers.contains(.control) { carbonModifiers |= UInt32(controlKey) }
            if eventModifiers.contains(.option) { carbonModifiers |= UInt32(optionKey) }
            if eventModifiers.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
            if eventModifiers.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
            
            // LOG EVERY KEYPRESS TO CONSOLE FOR DEBUGGING
            print("HotkeyService: [EVENT] KeyCode: \(eventKeyCode), Modifiers: \(carbonModifiers) (Target: \(keyCode)/\(modifiers))")
            
            if eventKeyCode == keyCode && carbonModifiers == modifiers {
                print("HotkeyService: [MATCH] Triggering Action!")
                DispatchQueue.main.async {
                    self?.onTrigger?()
                }
                return nil 
            }
            return event
        }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = handler(event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handler)
        print("HotkeyService: [SYSTEM] Monitors installed. If you don't see [EVENT] logs below, Accessibility is NOT enabled.")
    }
    
    func unregisterHotkey() {
        if let monitor = globalMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = localMonitor { NSEvent.removeMonitor(monitor) }
        globalMonitor = nil
        localMonitor = nil
        print("HotkeyService: [SYSTEM] Monitors removed.")
    }
}
