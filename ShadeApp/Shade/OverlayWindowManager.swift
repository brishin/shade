import AppKit
import SwiftUI

@Observable
class OverlayWindowManager {
    private var overlayWindow: NSWindow?

    func createOverlayWindow<Content: View>(content: Content) -> NSWindow {
        if let existingWindow = overlayWindow {
            return existingWindow
        }

        let window = NSWindow(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false

        window.contentView = NSHostingView(rootView: content)

        overlayWindow = window
        return window
    }

    func showOverlay() {
        overlayWindow?.orderFrontRegardless()
        overlayWindow?.alphaValue = 1.0
    }

    func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }

    func closeOverlay() {
        overlayWindow?.close()
        overlayWindow = nil
    }
}
