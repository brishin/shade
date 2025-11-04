import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.brishin.Shade", category: "DesktopOverlay")

@Observable
class OverlayState {
    var currentSpaceID: CGSSpaceID?

    init(currentSpaceID: CGSSpaceID? = nil) {
        self.currentSpaceID = currentSpaceID
    }
}

struct DesktopOverlayView: View {
    let windowManager: WindowManager
    var state: OverlayState

    var body: some View {
        let _ = logger.info("🎨 DesktopOverlayView body evaluated with currentSpaceID: \(self.state.currentSpaceID ?? 0)")
        let _ = logger.info("🎨 Spaces: \(self.spaces.map { "Space \($0.id): \($0.name)" }.joined(separator: ", "))")

        return VStack {
            Spacer()

            HStack(spacing: 16) {
                ForEach(spaces, id: \.id) { space in
                    let isActive = space.id == state.currentSpaceID
                    let _ = logger.info("🎨 Creating DesktopBoxView for Space \(space.id) (\(space.name)) - isActive: \(isActive) (comparing \(space.id) == \(self.state.currentSpaceID ?? 0))")

                    DesktopBoxView(
                        space: space,
                        isActive: isActive
                    )
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var spaces: [SpaceInfo] {
        let spacesList = windowManager.getSpacesInfo()
        return spacesList.isEmpty ? [] : spacesList
    }
}

struct DesktopBoxView: View {
    let space: SpaceInfo
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                if isActive {
                    Text("►")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.green)
                }

                Text(space.name)
                    .font(.system(.body, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("\(space.windowCount) windows")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 12.0))
        .onAppear {
            logger.info("📦 DesktopBoxView for Space \(space.id) (\(space.name)): isActive = \(isActive)")
        }
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
        state: OverlayState()
    )
}
