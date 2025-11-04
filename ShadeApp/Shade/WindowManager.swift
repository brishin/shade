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

        // Get managed display spaces using the CGSCopyManagedDisplaySpaces API
        guard let managedDisplaySpacesRef = CGSCopyManagedDisplaySpaces(connectionID) else {
            logger.warning("🪟 ⚠️ Failed to get managed display spaces")
            return
        }

        // Convert to NSArray
        let managedDisplaySpaces = managedDisplaySpacesRef.takeRetainedValue() as NSArray

        logger.info("🪟 Found \(managedDisplaySpaces.count) displays")

        var desktopCounter = 1

        // Iterate through each display
        for displayObj in managedDisplaySpaces {
            guard let displayDict = displayObj as? [String: Any] else {
                continue
            }

            // Get the "Spaces" array for this display
            guard let spacesArray = displayDict["Spaces"] as? [[String: Any]] else {
                continue
            }

            logger.info("🪟 Display has \(spacesArray.count) user desktops")

            // All Spaces returned by CGSCopyManagedDisplaySpaces are user desktops
            // Number them sequentially in the order they appear
            for spaceDict in spacesArray {
                // Extract space ID
                guard let spaceID = spaceDict["id64"] as? UInt64 else {
                    continue
                }

                // This is a user desktop - assign it a sequential number
                let spaceName = "Desktop \(desktopCounter)"
                spaceNameCache[spaceID] = spaceName
                logger.info("🪟 Space \(spaceID, privacy: .public): User desktop → \"\(spaceName, privacy: .public)\"")
                desktopCounter += 1
            }
        }

        logger.info("🪟 Space name cache built with \(self.spaceNameCache.count) entries, \(desktopCounter - 1) user desktops")
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

    func getCurrentSpaceID() -> CGSSpaceID {
        logger.info("🔄 getCurrentSpaceID called")
        let connectionID = CGSMainConnectionID()
        let maxRetries = 5
        let retryDelay: TimeInterval = 0.05 // 50 milliseconds

        for attempt in 1...maxRetries {
            let spaceID = CGSGetActiveSpace(connectionID)
            logger.info("🔄 Attempt \(attempt): CGSGetActiveSpace returned \(spaceID)")

            // A return value of 0 indicates failure - retry
            if spaceID != 0 {
                logger.info("🔄 getCurrentSpaceID succeeded with Space ID: \(spaceID)")
                return spaceID
            }

            // Wait before retrying (except on last attempt)
            if attempt < maxRetries {
                logger.info("🔄 Space ID was 0, retrying after \(retryDelay)s delay...")
                Thread.sleep(forTimeInterval: retryDelay)
            }
        }

        // All retries failed
        logger.warning("⚠️ getCurrentSpaceID failed after \(maxRetries) attempts - returning 0")
        return 0
    }

    func getSpacesInfo() -> [SpaceInfo] {
        let groupedBySpace = Dictionary(grouping: windows) { $0.spaceID }

        // Get all desktop Spaces from cache (those that start with "Desktop ")
        let desktopSpaces = spaceNameCache.filter { $0.value.hasPrefix("Desktop ") }
        let sortedSpaceIDs = desktopSpaces.keys.sorted()

        var spacesInfo: [SpaceInfo] = []

        for spaceID in sortedSpaceIDs {
            guard let spaceName = spaceNameCache[spaceID] else { continue }

            // Get window count (0 if no windows on this Space)
            let windowCount = groupedBySpace[spaceID]?.count ?? 0

            let spaceInfo = SpaceInfo(
                id: spaceID,
                name: spaceName,
                windowCount: windowCount
            )
            spacesInfo.append(spaceInfo)
        }

        return spacesInfo
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
