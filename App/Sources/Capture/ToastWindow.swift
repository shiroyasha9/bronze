import AppKit
import SwiftUI

@MainActor
enum ToastWindow {
    private static var current: NSWindow?

    static func show(_ message: String) {
        current?.orderOut(nil)

        let content: NSView
        if #available(macOS 26.0, *) {
            let label = NSHostingView(rootView: ToastContent(message: message))
            label.frame.size = label.fittingSize
            let glass = NSGlassEffectView(frame: NSRect(origin: .zero, size: label.fittingSize))
            glass.cornerRadius = label.fittingSize.height / 2
            glass.contentView = label
            content = glass
        } else {
            let label = NSHostingView(rootView: ToastLabel(message: message))
            label.frame.size = label.fittingSize
            content = label
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: content.frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = true
        window.contentView = content

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

