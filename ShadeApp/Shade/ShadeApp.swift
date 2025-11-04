//
//  ShadeApp.swift
//  Shade
//
//  Created by Brian Shin on 10/24/25.
//

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.brishin.Shade", category: "AppLifecycle")

@main
struct ShadeApp: App {
    @State private var accessibilityManager = AccessibilityManager()
    @State private var windowManager = WindowManager()
    @State private var keyMonitor = KeyMonitor()
    @State private var overlayWindowManager = OverlayWindowManager()
    @State private var overlayWindow: NSWindow?
    @State private var overlayState = OverlayState()

    init() {
        logger.info("🚀 Shade app initializing")

        // Trigger window enumeration and overlay setup after a short delay
        Task { @MainActor [self] in
            try? await Task.sleep(for: .seconds(0.5))
            let manager = AccessibilityManager()
            let winManager = WindowManager()
            if manager.isAccessibilityGranted {
                logger.info("🚀 App initialized with permissions - starting window enumeration")
                winManager.enumerateWindows()
            } else {
                logger.info("🔐 App initialized without permissions - skipping enumeration")
            }

            // Set up overlay window
            await setupOverlay()
        }
    }

    @MainActor
    private func setupOverlay() {
        logger.info("🎯 Setting up overlay window")
        keyMonitor.startMonitoring()

        // Register for Space change notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [self] _ in
            Task { @MainActor in
                let newSpaceID = self.windowManager.getCurrentSpaceID()
                logger.info("🔄 Space changed to: \(newSpaceID)")

                // Update overlay state if it's currently visible
                if self.overlayWindow?.isVisible == true {
                    self.overlayState.currentSpaceID = newSpaceID
                }
            }
        }

        // Create the overlay window (will be updated when Option is pressed)
        let overlayView = DesktopOverlayView(
            windowManager: windowManager,
            state: overlayState
        )
        overlayWindow = overlayWindowManager.createOverlayWindow(content: overlayView)

        // Observe option key changes
        Task { @MainActor in
            await observeKeyChanges()
        }
    }

    @MainActor
    private func observeKeyChanges() async {
        var previousState = false
        while true {
            try? await Task.sleep(for: .milliseconds(100))
            let currentState = keyMonitor.isOptionKeyPressed

            // Only act when state changes
            if currentState != previousState {
                previousState = currentState

                if currentState {
                    // Refresh window data and current space before showing
                    windowManager.enumerateWindows()
                    let fetchedSpaceID = windowManager.getCurrentSpaceID()
                    logger.info("🔍 Fetched Space ID: \(fetchedSpaceID)")

                    logger.info("🎯 Showing overlay for Space ID: \(fetchedSpaceID)")

                    // Update the overlay state
                    overlayState.currentSpaceID = fetchedSpaceID

                    overlayWindowManager.showOverlay()
                } else {
                    overlayWindowManager.hideOverlay()
                }
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("Shade", systemImage: "cursor.rays") {
            MenuBarContentView(
                accessibilityManager: accessibilityManager,
                keyMonitor: keyMonitor,
                windowManager: windowManager,
                overlayWindowManager: overlayWindowManager
            )
        }
        .menuBarExtraStyle(.menu)

        Window("Accessibility Permission", id: "accessibility-permission") {
            PermissionContentView(manager: accessibilityManager, windowManager: windowManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsContentView(
                accessibilityManager: accessibilityManager,
                windowManager: windowManager
            )
        }
    }
}

struct PermissionContentView: View {
    let manager: AccessibilityManager
    let windowManager: WindowManager
    @State private var permissionTimer: Timer?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if !manager.isAccessibilityGranted {
                AccessibilityPermissionView(manager: manager)
                    .onAppear {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        permissionTimer = manager.startMonitoring()
                    }
                    .onDisappear {
                        permissionTimer?.invalidate()
                    }
            } else {
                Color.clear
                    .frame(width: 0, height: 0)
                    .onAppear {
                        logger.info("🚀 Permission granted - closing permission window")

                        // Close the permission window
                        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "accessibility-permission" }) {
                            logger.info("🚀 Closing permission window")
                            window.close()
                        }
                    }
            }
        }
        .onAppear {
            // If permissions are already granted on first appearance, close window immediately
            if manager.isAccessibilityGranted {
                logger.info("🚀 Permissions already granted on launch - closing permission window")

                // Close the window immediately
                DispatchQueue.main.async {
                    if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "accessibility-permission" }) {
                        logger.info("🚀 Closing permission window (already granted)")
                        window.close()
                    }
                }
            }
        }
    }
}

struct SettingsContentView: View {
    let accessibilityManager: AccessibilityManager
    let windowManager: WindowManager

    var body: some View {
        Group {
            if accessibilityManager.isAccessibilityGranted {
                ContentView()
            } else {
                Text("Please grant accessibility permission first")
                    .foregroundStyle(.secondary)
                    .frame(width: 400, height: 200)
            }
        }
        .onAppear {
            if accessibilityManager.isAccessibilityGranted {
                logger.info("🚀 App launched with permissions - starting window enumeration")
                windowManager.enumerateWindows()
            }
        }
        .onChange(of: accessibilityManager.isAccessibilityGranted) { oldValue, newValue in
            if newValue {
                logger.info("🚀 Accessibility permission granted - starting window enumeration")
                windowManager.enumerateWindows()
            }
        }
    }
}

struct MenuBarContentView: View {
    let accessibilityManager: AccessibilityManager
    let keyMonitor: KeyMonitor
    let windowManager: WindowManager
    let overlayWindowManager: OverlayWindowManager

    var body: some View {
        Button("Settings...") {
            NSApplication.shared.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        .keyboardShortcut(",")
        .disabled(!accessibilityManager.isAccessibilityGranted)

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
