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
    let spaceName: String?

    var description: String {
        let titleText = title ?? "(no title)"
        let spaceText: String
        if let name = spaceName {
            spaceText = name
        } else if let id = spaceID {
            spaceText = "Space \(id)"
        } else {
            spaceText = "Unknown Space"
        }
        let position = "{\(Int(bounds.origin.x)), \(Int(bounds.origin.y)), \(Int(bounds.size.width)), \(Int(bounds.size.height))}"
        return "[\(spaceText)] \(ownerName) - \(titleText) (ID: \(id), PID: \(ownerPID), Layer: \(layer)) at \(position)"
    }
}
