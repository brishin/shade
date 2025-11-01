import Foundation
import ApplicationServices
import AppKit
import OSLog

private let logger = Logger(subsystem: "com.brishin.Shade", category: "AccessibilityManager")

@Observable
class AccessibilityManager {
    var isAccessibilityGranted: Bool = false

    init() {
        logger.info("🔐 AccessibilityManager initialized")
        checkAccessibilityPermission()
    }

    func checkAccessibilityPermission() {
        isAccessibilityGranted = AXIsProcessTrusted()
        logger.info("🔐 Accessibility permission status: \(self.isAccessibilityGranted ? "✅ GRANTED" : "❌ DENIED")")
    }

    func requestAccessibilityPermission() {
        logger.info("🔐 Requesting accessibility permission from user")
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
        logger.info("🔐 Permission request result: \(self.isAccessibilityGranted ? "✅ GRANTED" : "❌ DENIED")")
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
