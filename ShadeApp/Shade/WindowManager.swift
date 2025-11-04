import Foundation
import CoreGraphics
import AppKit
import OSLog

private let logger = Logger(subsystem: "com.brishin.Shade", category: "WindowManager")

@Observable
class WindowManager {
    var windows: [WindowInfo] = []
    private var spaceNameCache: [CGSSpaceID: String] = [:]

    func enumerateWindows() {
        logger.info("🪟 Starting window enumeration")

        // Get the window server connection
        let connectionID = CGSMainConnectionID()

        // Build Space name cache
        buildSpaceNameCache(connectionID: connectionID)

        // Get all windows using Core Graphics Window Services
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            logger.error("🪟 ❌ Failed to get window list")
            return
        }

        logger.info("🪟 Found \(windowList.count) windows to process")

        var windowInfos: [WindowInfo] = []

        for windowDict in windowList {
            // Extract window properties
            guard let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID,
                  let ownerPID = windowDict[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
                  let boundsDict = windowDict[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = windowDict[kCGWindowLayer as String] as? Int else {
                continue
            }

            // Parse bounds
            let x = boundsDict["X"] ?? 0
            let y = boundsDict["Y"] ?? 0
            let width = boundsDict["Width"] ?? 0
            let height = boundsDict["Height"] ?? 0
            let bounds = CGRect(x: x, y: y, width: width, height: height)

            // Get window title (optional)
            let title = windowDict[kCGWindowName as String] as? String

            // Get Space ID using private API
            let spaceID = getSpaceIDForWindow(windowID, connectionID: connectionID)

            // Get Space name from cache
            let spaceName = spaceID.flatMap { spaceNameCache[$0] }

            let windowInfo = WindowInfo(
                id: windowID,
                title: title,
                ownerName: ownerName,
                ownerPID: ownerPID,
                bounds: bounds,
                layer: layer,
                spaceID: spaceID,
                spaceName: spaceName
            )

            windowInfos.append(windowInfo)
        }

        // Sort by Space ID, then by owner name
        windowInfos.sort { lhs, rhs in
            if let lhsSpace = lhs.spaceID, let rhsSpace = rhs.spaceID {
                if lhsSpace != rhsSpace {
                    return lhsSpace < rhsSpace
                }
            }
            return lhs.ownerName < rhs.ownerName
        }

        self.windows = windowInfos

        logger.info("🪟 Successfully enumerated \(windowInfos.count) windows")

        // Log window information
        logWindows(windowInfos)
    }

    private func buildSpaceNameCache(connectionID: CGSConnectionID) {
        logger.info("🪟 Building Space name cache")

        // Clear existing cache
        spaceNameCache.removeAll()

        // Get all Spaces using private API
        guard let spacesArrayRef = CGSCopySpaces(connectionID, Int32(kCGSAllSpacesMask)) else {
            logger.warning("🪟 ⚠️ Failed to get Spaces list")
            return
        }

        // Convert Unmanaged<CFArray> to NSArray safely (same pattern as getSpaceIDForWindow)
        let spacesArray = spacesArrayRef.takeRetainedValue() as NSArray

        logger.info("🪟 Found \(spacesArray.count) Spaces")

        // Iterate through all Spaces and get their names
        var desktopIndex = 1
        for spaceObj in spacesArray {
            guard let spaceID = (spaceObj as? NSNumber)?.uint64Value else {
                continue
            }

            var spaceName: String? = nil

            // Try to get the Space name using CGSSpaceCopyName
            if let spaceNameRef = CGSSpaceCopyName(connectionID, spaceID) {
                let name = spaceNameRef.takeRetainedValue() as String
                logger.debug("🪟 Space \(spaceID, privacy: .public): CGSSpaceCopyName returned \"\(name, privacy: .public)\"")

                // If the name is not empty and not just a UUID, use it
                // Otherwise fall through to index-based naming
                if !name.isEmpty {
                    // Check if this is a meaningful name (not empty, not just whitespace, not a UUID pattern)
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

                    // Simple heuristic: if name contains "Desktop" or is very long (likely a UUID),
                    // use index-based naming instead
                    if !trimmedName.isEmpty &&
                       !trimmedName.contains(where: { $0 == "-" && trimmedName.count > 30 }) {
                        spaceName = trimmedName
                    }
                }
            }

            // Fallback: Use index-based naming (Desktop 1, Desktop 2, etc.)
            // This provides a predictable, user-friendly name when CGS doesn't return a good name
            if spaceName == nil {
                spaceName = "Desktop \(desktopIndex)"
                logger.debug("🪟 Space \(spaceID, privacy: .public): Using index-based name \"\(spaceName!, privacy: .public)\"")
            }

            spaceNameCache[spaceID] = spaceName
            desktopIndex += 1
        }

        logger.info("🪟 Space name cache built with \(self.spaceNameCache.count) entries")
    }

    private func getSpaceIDForWindow(_ windowID: CGWindowID, connectionID: CGSConnectionID) -> CGSSpaceID? {
        // Create array with single window ID
        let windowArray = [windowID] as CFArray

        // Get Spaces for this window using private API
        guard let spacesRef = CGSCopySpacesForWindows(connectionID, Int32(kCGSAllSpacesMask), windowArray) else {
            return nil
        }

        // Convert Unmanaged<CFArray> to NSArray safely
        let spaces = spacesRef.takeRetainedValue() as NSArray
        guard spaces.count > 0 else {
            return nil
        }

        // Get first space ID as NSNumber and convert to CGSSpaceID
        guard let spaceNumber = spaces.firstObject as? NSNumber else {
            return nil
        }

        return spaceNumber.uint64Value
    }

    private func logWindows(_ windows: [WindowInfo]) {
        logger.info("🪟 ═══════════════════════════════════════")
        logger.info("🪟 Window Enumeration Results: \(windows.count) total windows")

        // Group windows by Space
        let groupedBySpace = Dictionary(grouping: windows) { $0.spaceID }
        let sortedSpaces = groupedBySpace.keys.sorted { ($0 ?? 0) < ($1 ?? 0) }

        for spaceID in sortedSpaces {
            guard let windowsInSpace = groupedBySpace[spaceID] else { continue }

            let spaceHeader: String
            if let space = spaceID {
                if let spaceName = self.spaceNameCache[space] {
                    spaceHeader = "\(spaceName) (ID: \(space))"
                } else {
                    spaceHeader = "Space \(space)"
                }
            } else {
                spaceHeader = "Unknown Space"
            }

            logger.info("🪟 ┌─ \(spaceHeader, privacy: .public) (\(windowsInSpace.count) windows)")

            for window in windowsInSpace {
                logger.info("🪟 │  \(window.description, privacy: .public)")
            }

            logger.info("🪟 └─")
        }

        // Summary statistics
        let windowsPerSpace = groupedBySpace.mapValues { $0.count }
        logger.info("🪟 Summary: \(groupedBySpace.count) Spaces, distribution: \(windowsPerSpace, privacy: .public)")
        logger.info("🪟 ═══════════════════════════════════════")
    }
}
