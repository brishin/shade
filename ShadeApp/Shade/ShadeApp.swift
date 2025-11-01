//
//  ShadeApp.swift
//  Shade
//
//  Created by Brian Shin on 10/24/25.
//

import SwiftUI

@main
struct ShadeApp: App {
    @State private var accessibilityManager = AccessibilityManager()

    var body: some Scene {
        Window("Accessibility Permission", id: "accessibility-permission") {
            PermissionContentView(manager: accessibilityManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)

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

        Settings {
            if accessibilityManager.isAccessibilityGranted {
                ContentView()
            } else {
                Text("Please grant accessibility permission first")
                    .foregroundStyle(.secondary)
                    .frame(width: 400, height: 200)
            }
        }
    }
}

struct PermissionContentView: View {
    let manager: AccessibilityManager
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
                        if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "accessibility-permission" }) {
                            window.close()
                        }
                    }
            }
        }
    }
}
