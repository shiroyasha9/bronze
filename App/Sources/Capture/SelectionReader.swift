import AppKit
import ApplicationServices
import os

let captureLog = Logger(subsystem: "tech.teensy.bronze", category: "capture")

protocol SelectionReader {
    func readSelection() async -> String?
}

struct AXSelectionReader: SelectionReader {
    func readSelection() async -> String? {
        let front = NSWorkspace.shared.frontmostApplication
        captureLog.info("AX: frontmost=\(front?.bundleIdentifier ?? "nil", privacy: .public)")

        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let focusErr = AXUIElementCopyAttributeValue(
            systemWide, kAXFocusedUIElementAttribute as CFString, &focused
        )
        guard focusErr == .success, let element = focused else {
            captureLog.info("AX: no focused element, err=\(focusErr.rawValue, privacy: .public)")
            return nil
        }

        var selected: CFTypeRef?
        let selErr = AXUIElementCopyAttributeValue(
            element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selected
        )
        let text = selected as? String
        captureLog.info("AX: selectedText err=\(selErr.rawValue, privacy: .public) len=\(text?.count ?? -1, privacy: .public)")
        guard selErr == .success, let text, !text.isEmpty else { return nil }
        return text
    }
}

/// Simulates ⌘C, reads the pasteboard, then restores its previous contents.
struct PasteboardSelectionReader: SelectionReader {
    var onOwnWrite: @MainActor () -> Void = {}

    func readSelection() async -> String? {
        let pasteboard = NSPasteboard.general
        let saved = pasteboard.string(forType: .string)
        let savedChangeCount = pasteboard.changeCount

        postCmdC()
        try? await Task.sleep(for: .milliseconds(150))

        let changed = pasteboard.changeCount != savedChangeCount
        let text = pasteboard.string(forType: .string)
        captureLog.info("Fallback: changed=\(changed, privacy: .public) len=\(text?.count ?? -1, privacy: .public)")
        guard changed else { return nil }

        if let saved {
            pasteboard.clearContents()
            pasteboard.setString(saved, forType: .string)
            await onOwnWrite()
        }
        return text?.isEmpty == false ? text : nil
    }

    private func postCmdC() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

