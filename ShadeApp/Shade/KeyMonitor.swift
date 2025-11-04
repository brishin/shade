import AppKit
import SwiftUI

@Observable
class KeyMonitor {
    var isOptionKeyPressed = false
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func startMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
    }

    func stopMonitoring() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let newState = event.modifierFlags.contains(.option)
        if newState != isOptionKeyPressed {
            isOptionKeyPressed = newState
        }
    }

    deinit {
        stopMonitoring()
    }
}
