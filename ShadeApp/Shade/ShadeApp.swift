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

    init() {
        logger.info("🚀 Shade app initializing")

        // Trigger window enumeration after a short delay to allow app to fully initialize
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            let manager = AccessibilityManager()
            let winManager = WindowManager()
            if manager.isAccessibilityGranted {
                logger.info("🚀 App initialized with permissions - starting window enumeration")
                winManager.enumerateWindows()
            } else {
                logger.info("🔐 App initialized without permissions - skipping enumeration")
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("Shade", systemImage: "cursor.rays") {
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
