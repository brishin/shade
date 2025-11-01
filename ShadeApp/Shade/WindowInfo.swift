import Foundation
import CoreGraphics

struct WindowInfo: Identifiable {
    let id: CGWindowID
    let title: String?
    let ownerName: String
    let ownerPID: pid_t
    let bounds: CGRect
    let layer: Int
    let spaceID: CGSSpaceID?

    var description: String {
        let titleText = title ?? "(no title)"
        let spaceText = spaceID.map { "Space \($0)" } ?? "Unknown Space"
        let position = "{\(Int(bounds.origin.x)), \(Int(bounds.origin.y)), \(Int(bounds.size.width)), \(Int(bounds.size.height))}"
        return "[\(spaceText)] \(ownerName) - \(titleText) (ID: \(id), PID: \(ownerPID), Layer: \(layer)) at \(position)"
    }
}
