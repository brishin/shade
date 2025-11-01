import Foundation
import ApplicationServices
import AppKit

@Observable
class AccessibilityManager {
    var isAccessibilityGranted: Bool = false

    init() {
        checkAccessibilityPermission()
    }

    func checkAccessibilityPermission() {
        isAccessibilityGranted = AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func startMonitoring(interval: TimeInterval = 1.0) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkAccessibilityPermission()
        }
    }
}
