import SwiftUI

struct AccessibilityPermissionView: View {
    let manager: AccessibilityManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("Accessibility Permission Required")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Shade needs accessibility access to function properly. Click the button below to grant permission.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 400)
            }

            Button(action: {
                manager.requestAccessibilityPermission()
            }) {
                Text("Grant Permission")
                    .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text("After enabling, this window will close automatically")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(width: 500, height: 400)
    }
}

#Preview {
    AccessibilityPermissionView(manager: AccessibilityManager())
}
