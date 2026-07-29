import AppKit
import ApplicationServices

@MainActor
final class CaptureController {
    private let model: AppModel
    private let reader: SelectionReader
    private var flagsMonitors: [Any] = []
    private var keyMonitor: Any?
    private var lastShiftPress: Date?
    private var shiftWasDown = false
    private var capturing = false

    private static let doubleTapWindow: TimeInterval = 0.35

    init(model: AppModel) {
        self.model = model
        self.reader = ChainedSelectionReader(readers: [
            AXSelectionReader(),
            PasteboardSelectionReader(),
        ])
        requestAccessibilityIfNeeded()
        installMonitors()
    }

    private func requestAccessibilityIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    private func installMonitors() {
        let handleFlags: (NSEvent) -> Void = { [weak self] event in
            Task { @MainActor in self?.handleFlagsChanged(event) }
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handleFlags) {
            flagsMonitors.append(global)
        }
        flagsMonitors.append(NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handleFlags(event)
            return event
        } as Any)
        // Any real keypress between shift taps cancels the chord.
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            Task { @MainActor in self?.lastShiftPress = nil }
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let shiftDown = flags.contains(.shift)
        let onlyShift = flags.subtracting(.shift).isEmpty

        defer { shiftWasDown = shiftDown }
        guard shiftDown, !shiftWasDown, onlyShift else { return }

        let now = Date()
        if let last = lastShiftPress, now.timeIntervalSince(last) < Self.doubleTapWindow {
            lastShiftPress = nil
            triggerCapture()
        } else {
            lastShiftPress = now
        }
    }

    private func triggerCapture() {
        guard !capturing, AXIsProcessTrusted() else { return }
        capturing = true
        Task { @MainActor in
            defer { capturing = false }
            guard let text = await reader.readSelection() else { return }
            model.capture(text: text)
            ToastWindow.show("Captured")
        }
    }
}
