//
//  ContentView.swift
//  Shade
//
//  Created by Brian Shin on 10/24/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cursor.rays")
                .imageScale(.large)
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Shade Settings")
                .font(.title)

            Text("Configure your preferences here")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
