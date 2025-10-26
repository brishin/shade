//
//  ShadeApp.swift
//  Shade
//
//  Created by Brian Shin on 10/24/25.
//

import SwiftUI

@main
struct ShadeApp: App {
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra("Shade", systemImage: "cursor.rays") {
            Button("Settings...") {
                // Activate the app so the settings window appears in front
                NSApplication.shared.activate(ignoringOtherApps: true)
                openSettings()
            }
            .keyboardShortcut(",")

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            ContentView()
        }
    }
}
