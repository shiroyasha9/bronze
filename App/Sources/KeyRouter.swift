import AppKit
import BronzeCore

@MainActor
final class KeyRouter {
    private let model: AppModel
    private weak var panel: NSPanel?
    private var monitor: Any?
    private var pendingKey: (char: Character, at: Date)?

    private static let pendingTimeout: TimeInterval = 0.4

    init(model: AppModel, panel: NSPanel) {
        self.model = model
        self.panel = panel
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.shouldHandle(event) else { return event }
            return self.handle(event) ? nil : event
        }
    }

    deinit {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func shouldHandle(_ event: NSEvent) -> Bool {
        guard let panel, event.window === panel, panel.isKeyWindow else { return false }
        // Insert mode: any focused text field owns the keyboard, except ⌘/.
        if panel.firstResponder is NSTextView {
            return event.modifierFlags.contains(.command)
                && event.charactersIgnoringModifiers == "/"
        }
        return true
    }

    private func consumePending() -> Character? {
        defer { pendingKey = nil }
        guard let pending = pendingKey,
              Date().timeIntervalSince(pending.at) < Self.pendingTimeout else { return nil }
        return pending.char
    }

    private func handle(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let shift = flags.contains(.shift)

        if model.showShortcutGuide {
            return handleGuideKey(event, flags: flags)
        }

        if flags.contains(.command) {
            guard let char = event.charactersIgnoringModifiers?.lowercased() else { return false }
            switch char {
            case "c":
                shift ? model.copySelectionAsList() : model.copySelection()
                return true
            case "f":
                model.searchRequest += 1
                return true
            case "n":
                shift ? model.promptNewSection() : (model.composerRequest += 1)
                return true
            case "/":
                model.toggleShortcutGuide()
                return true
            default:
                return false
            }
        }

        if flags.contains(.option) {
            switch event.keyCode {
            case 38: model.reorderSelection(down: true); return true   // ⌥J
            case 40: model.reorderSelection(down: false); return true  // ⌥K
            default: return false
            }
        }

        if flags.contains(.control) {
            switch event.charactersIgnoringModifiers {
            case "d": model.halfPageJump(down: true); return true
            case "u": model.halfPageJump(down: false); return true
            default: return false
            }
        }

        switch event.keyCode {
        case 125: model.moveCursor(delta: 1, extend: shift || model.visualMode); return true
        case 126: model.moveCursor(delta: -1, extend: shift || model.visualMode); return true
        case 36: model.startEditingSelection(); return true            // Return
        case 51: model.deleteSelection(); return true                  // Delete
        case 49: model.toggleDoneSelection(); return true              // Space
        case 53: return handleEscape()
        default: break
        }

        guard let char = event.charactersIgnoringModifiers?.first else { return false }
        let pending = consumePending()

        switch char {
        case "j": model.moveCursor(delta: 1, extend: model.visualMode); return true
        case "k": model.moveCursor(delta: -1, extend: model.visualMode); return true
        case "g":
            if pending == "g" {
                model.selectFirst()
            } else {
                pendingKey = ("g", Date())
            }
            return true
        case "G": model.selectLast(); return true
        case "{": model.jumpSection(forward: false); return true
        case "}": model.jumpSection(forward: true); return true
        case "z":
            if pending == "z" {
                model.centerSelection()
            } else {
                pendingKey = ("z", Date())
            }
            return true
        case "x": model.toggleDoneSelection(); return true
        case "d":
            if pending == "d" {
                model.deleteSelection()
            } else {
                pendingKey = ("d", Date())
            }
            return true
        case "o": model.openNote(below: true); return true
        case "O": model.openNote(below: false); return true
        case "i": model.startEditingSelection(); return true
        case "y":
            model.selectedIds.count > 1 ? model.copySelectionAsList() : model.copySelection()
            model.visualMode = false
            return true
        case "p": model.pasteAsNote(); return true
        case "V", "v":
            model.visualMode.toggle()
            return true
        case "/": model.searchRequest += 1; return true
        case "?": model.toggleShortcutGuide(); return true
        case "m": showMoveMenu(); return true
        default: return false
        }
    }

    /// Guide swallows plain keys so browsing can't mutate notes; command
    /// chords other than ⌘/ still reach the menu bar.
    private func handleGuideKey(_ event: NSEvent, flags: NSEvent.ModifierFlags) -> Bool {
        if flags.contains(.command) {
            guard event.charactersIgnoringModifiers == "/" else { return false }
            model.toggleShortcutGuide()
            return true
        }
        if event.keyCode == 53 {
            model.toggleShortcutGuide()
            return true
        }
        switch event.charactersIgnoringModifiers?.first {
        case "?": model.toggleShortcutGuide()
        case "j": model.guideScrollStep += 1
        case "k": model.guideScrollStep -= 1
        default: break
        }
        return true
    }

    private func handleEscape() -> Bool {
        if model.visualMode {
            model.visualMode = false
            return true
        }
        if !model.query.isEmpty {
            model.query = ""
            return true
        }
        if !model.selectedIds.isEmpty {
            model.selectedIds = []
            return true
        }
        return false // falls through to cancelOperation → panel hides
    }

    private func showMoveMenu() {
        guard let panel, let anchorId = model.anchorId else { return }
        let menu = NSMenu(title: "Move to")
        let addItem = { (title: String, action: @escaping () -> Void) in
            let item = NSMenuItem(title: title, action: #selector(MenuAction.fire), keyEquivalent: "")
            let target = MenuAction(action)
            item.target = target
            item.representedObject = target
            menu.addItem(item)
        }
        addItem("No Section") { [model] in model.moveSelection(anchorId, to: nil) }
        for section in model.store.sections {
            addItem(section.name) { [model] in model.moveSelection(anchorId, to: section.id) }
        }
        menu.addItem(.separator())
        addItem("New Section…") { [model] in model.promptNewSection(moving: anchorId) }
        if let contentView = panel.contentView {
            menu.popUp(positioning: nil, at: NSPoint(x: 40, y: contentView.bounds.midY), in: contentView)
        }
    }
}

private final class MenuAction: NSObject {
    private let action: () -> Void

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    @objc func fire() {
        action()
    }
}
