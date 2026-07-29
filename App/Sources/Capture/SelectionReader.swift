import AppKit
import ApplicationServices

protocol SelectionReader {
    func readSelection() async -> String?
}

struct AXSelectionReader: SelectionReader {
    func readSelection() async -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemWide, kAXFocusedUIElementAttribute as CFString, &focused
        ) == .success, let element = focused else { return nil }

        var selected: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selected
        ) == .success, let text = selected as? String, !text.isEmpty else { return nil }
        return text
    }
}

/// Simulates ⌘C, reads the pasteboard, then restores its previous contents.
struct PasteboardSelectionReader: SelectionReader {
    func readSelection() async -> String? {
        let pasteboard = NSPasteboard.general
        let saved = pasteboard.string(forType: .string)
        let savedChangeCount = pasteboard.changeCount

        postCmdC()
        try? await Task.sleep(for: .milliseconds(150))

        defer {
            if let saved {
                pasteboard.clearContents()
                pasteboard.setString(saved, forType: .string)
            }
        }
        guard pasteboard.changeCount != savedChangeCount else { return nil }
        let text = pasteboard.string(forType: .string)
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

struct ChainedSelectionReader: SelectionReader {
    let readers: [SelectionReader]

    func readSelection() async -> String? {
        for reader in readers {
            if let text = await reader.readSelection() {
                return text
            }
        }
        return nil
    }
}
