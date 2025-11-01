//
//  ContentView.swift
//  Shade
//
//  Created by Brian Shin on 10/24/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: "cursor.rays")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Shade")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Display settings and controls")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(20)
            .background(.background.opacity(0.5))

            Divider()

            Form {
                Section {
                    Text("Settings will appear here")
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    ContentView()
}
