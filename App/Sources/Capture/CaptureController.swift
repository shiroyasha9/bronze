import AppKit
import ApplicationServices

@MainActor
final class CaptureController {
    private let model: AppModel
    private let tracker: PasteboardTracker
    private let axReader = AXSelectionReader()
    private let cmdCReader: PasteboardSelectionReader
    private var flagsMonitors: [Any] = []
    private var keyMonitor: Any?
    private var lastShiftPress: Date?
    private var shiftWasDown = false
    private var capturing = false

    private static let doubleTapWindow: TimeInterval = 0.35

    init(model: AppModel, tracker: PasteboardTracker) {
        self.model = model
        self.tracker = tracker
        self.cmdCReader = PasteboardSelectionReader(onOwnWrite: { tracker.noteOwnWrite() })
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
        captureLog.info("Chord: double-shift detected, trusted=\(AXIsProcessTrusted(), privacy: .public)")
        guard !capturing, AXIsProcessTrusted() else { return }
        capturing = true
        Task { @MainActor in
            defer { capturing = false }

            if let text = await axReader.readSelection() {
                captureLog.info("Capture: AX, \(text.count, privacy: .public) chars")
                model.capture(text: text)
                ToastWindow.show("Captured")
                return
            }
            // Copy-on-select apps (terminal TUIs) already put the selection on
            // the clipboard; a fresh external change is the only signal they give.
            if let text = tracker.freshExternalText, !text.isEmpty {
                captureLog.info("Capture: fresh clipboard, \(text.count, privacy: .public) chars")
                model.capture(text: text)
                ToastWindow.show("Captured from clipboard")
                return
            }
            if let text = await cmdCReader.readSelection() {
                captureLog.info("Capture: cmd-c fallback, \(text.count, privacy: .public) chars")
                model.capture(text: text)
                ToastWindow.show("Captured")
                return
            }
            captureLog.info("Capture: no selection found")
        }
    }
}
