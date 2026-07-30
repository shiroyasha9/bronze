import AppKit
import Combine
import SwiftUI

/// Vetoes isMovableByWindowBackground over a region so SwiftUI drag
/// gestures there win against the AppKit window-move.
struct ImmovableRegion: NSViewRepresentable {
    final class ImmovableView: NSView {
        override var mouseDownCanMoveWindow: Bool { false }
    }

    func makeNSView(context: Context) -> NSView { ImmovableView() }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        orderOut(nil)
    }
}

@MainActor
final class PanelController {
    private let panel: FloatingPanel
    private var keyRouter: KeyRouter?
    private var pinSubscription: AnyCancellable?

    init(model: AppModel) {
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 560),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.level = model.pinToForeground ? .floating : .normal
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let root = PanelRootView()
            .environmentObject(model)
        let hosting = NSHostingView(rootView: root)
        panel.contentView = hosting

        keyRouter = KeyRouter(model: model, panel: panel)
        model.panelWindow = panel

        pinSubscription = model.$pinToForeground.sink { [weak panel] pinned in
            panel?.level = pinned ? .floating : .normal
        }

        panel.setFrameAutosaveName("BronzePanel")
        if panel.frame.origin == .zero, let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: frame.maxX - panel.frame.width - 24,
                y: frame.midY - panel.frame.height / 2
            ))
        }
    }

    func show() {
        panel.orderFrontRegardless()
        panel.makeKey()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        panel.isKeyWindow ? hide() : show()
    }
}
