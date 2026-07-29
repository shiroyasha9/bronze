import AppKit
import BronzeCore
import SwiftUI

struct ScrollTarget: Equatable {
    let id: UUID
    let anchor: UnitPoint
}

extension AppModel {
    func select(_ id: UUID, extend: Bool) {
        editingId = nil
        if extend {
            if let existing = selectedIds.firstIndex(of: id) {
                selectedIds.remove(at: existing)
            } else {
                selectedIds.append(id)
            }
        } else {
            selectedIds = [id]
        }
    }

    func selectIfUnselected(_ id: UUID) {
        if !selectedIds.contains(id) {
            selectedIds = [id]
        }
    }

    func moveSelection(_ anchor: UUID, to sectionId: UUID?) {
        selectIfUnselected(anchor)
        mutate { $0.moveNotes(ids: Set(selectedIds), to: sectionId) }
        scrollTo(anchor)
    }

    func promptNewSection(moving noteId: UUID? = nil) {
        let alert = NSAlert()
        alert.messageText = "New Section"
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        field.placeholderString = "Section name"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = field.stringValue.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        mutate {
            let section = $0.createSection(name: name)
            if let noteId {
                $0.moveNotes(ids: [noteId], to: section.id)
            }
        }
        if let noteId { scrollTo(noteId) }
    }

    func attributedText(for note: Note) -> AttributedString {
        var attributed = (try? AttributedString(
            markdown: note.text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(note.text)

        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return attributed }
        var searchStart = attributed.startIndex
        while let range = attributed[searchStart...].range(
            of: trimmedQuery, options: .caseInsensitive
        ) {
            attributed[range].backgroundColor = Bronze.accent.opacity(0.3)
            searchStart = range.upperBound
        }
        return attributed
    }
}
