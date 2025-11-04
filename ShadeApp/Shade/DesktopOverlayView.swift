import SwiftUI

struct DesktopOverlayView: View {
    let windowManager: WindowManager
    let currentSpaceID: CGSSpaceID?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(topBorder)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)

                Text(separator)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)

                ForEach(spaceInfoLines, id: \.self) { line in
                    Text(line)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(line.contains("►") ? .green : .white)
                }

                Text(bottomBorder)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.95)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var topBorder: String {
        "╔═══════════════════════════════════════╗"
    }

    private var bottomBorder: String {
        "╚═══════════════════════════════════════╝"
    }

    private var separator: String {
        "╟───────────────────────────────────────╢"
    }

    private var title: String {
        "║          DESKTOP OVERVIEW           ║"
    }

    private var spaceInfoLines: [String] {
        let spaces = windowManager.getSpacesInfo()
        var lines: [String] = []

        for space in spaces {
            let isActive = space.id == currentSpaceID
            let indicator = isActive ? "► " : "  "
            let spaceName = space.name.padding(toLength: 12, withPad: " ", startingAt: 0)
            let windowCount = "\(space.windowCount) windows".padding(toLength: 12, withPad: " ", startingAt: 0)

            let line = "║ \(indicator)\(spaceName) │ \(windowCount) ║"
            lines.append(line)
        }

        if lines.isEmpty {
            lines.append("║  No desktop information available    ║")
        }

        return lines
    }
}

struct SpaceInfo {
    let id: CGSSpaceID
    let name: String
    let windowCount: Int
}

#Preview {
    DesktopOverlayView(
        windowManager: WindowManager(),
        currentSpaceID: nil
    )
}
