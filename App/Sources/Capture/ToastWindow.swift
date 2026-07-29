import AppKit
import SwiftUI

@MainActor
enum ToastWindow {
    private static var current: NSWindow?

    static func show(_ message: String) {
        current?.orderOut(nil)

        let label = NSHostingView(rootView: ToastLabel(message: message))
        label.frame.size = label.fittingSize

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: label.fittingSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.contentView = label

        let mouse = NSEvent.mouseLocation
        window.setFrameOrigin(NSPoint(x: mouse.x + 16, y: mouse.y + 16))
        window.orderFrontRegardless()
        current = window

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            if current === window {
                window.orderOut(nil)
                current = nil
            }
        }
    }
}

private struct ToastLabel: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.85), in: Capsule())
    }
}
