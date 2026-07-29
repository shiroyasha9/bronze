import BronzeCore
import Foundation
import SwiftUI

extension AppModel {
    var anchorId: UUID? { selectedIds.last }

    private var anchorIndex: Int? {
        guard let anchorId else { return nil }
        return visibleNotes.firstIndex { $0.id == anchorId }
    }

    func moveCursor(delta: Int, extend: Bool) {
        let notes = visibleNotes
        guard !notes.isEmpty else { return }
        guard let current = anchorIndex else {
            selectIndex(delta > 0 ? 0 : notes.count - 1)
            return
        }
        let target = max(0, min(notes.count - 1, current + delta))
        if extend {
            let id = notes[target].id
            if selectedIds.contains(id) {
                if selectedIds.count > 1 { selectedIds.removeLast() }
            } else {
                selectedIds.append(id)
            }
            scrollTo(id)
        } else {
            selectIndex(target)
        }
    }

    func selectIndex(_ index: Int, anchor: UnitPoint = .center) {
        let notes = visibleNotes
        guard notes.indices.contains(index) else { return }
        selectedIds = [notes[index].id]
        scrollTo(notes[index].id, anchor: anchor)
    }

    func selectFirst() { selectIndex(0, anchor: .top) }
    func selectLast() { selectIndex(visibleNotes.count - 1, anchor: .bottom) }

    func halfPageJump(down: Bool) {
        guard let current = anchorIndex else {
            down ? selectFirst() : selectLast()
            return
        }
        moveCursorTo(index: current + (down ? 8 : -8))
    }

    private func moveCursorTo(index: Int) {
        selectIndex(max(0, min(visibleNotes.count - 1, index)))
    }

    func jumpSection(forward: Bool) {
        let groups = self.groups.filter { !$0.notes.isEmpty }
        guard !groups.isEmpty else { return }
        let starts = groups.map { $0.notes[0].id }
        let notes = visibleNotes
        guard let current = anchorIndex else {
            selectFirst()
            return
        }
        let currentId = notes[current].id
        let groupIndex = groups.firstIndex { $0.notes.contains { $0.id == currentId } } ?? 0
        let target = forward
            ? min(groups.count - 1, groupIndex + 1)
            : (starts[groupIndex] == currentId ? max(0, groupIndex - 1) : groupIndex)
        if let index = notes.firstIndex(where: { $0.id == starts[target] }) {
            selectIndex(index)
        }
    }

    func centerSelection() {
        guard let anchorId else { return }
        scrollTo(anchorId, anchor: .center)
    }

    private func scrollTo(_ id: UUID, anchor: UnitPoint = .center) {
        scrollTarget = ScrollTarget(id: id, anchor: anchor)
    }

    func startEditingSelection() {
        guard let anchorId else { return }
        editingId = anchorId
    }

    func openNote(below: Bool) {
        guard let anchorId else {
            composerRequest += 1
            return
        }
        mutate {
            let inserted = below
                ? $0.insertNote(text: "", after: anchorId)
                : $0.insertNote(text: "", before: anchorId)
            if let inserted {
                selectedIds = [inserted.id]
                editingId = inserted.id
            }
        }
    }

    func pasteAsNote() {
        guard let text = NSPasteboard.general.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else { return }
        if let anchorId {
            mutate {
                if let inserted = $0.insertNote(text: text, after: anchorId) {
                    selectedIds = [inserted.id]
                }
            }
        } else {
            addNote(text: text)
        }
    }

    func reorderSelection(down: Bool) {
        guard let anchorId, selectedIds.count == 1 else { return }
        mutate { down ? $0.moveNoteDown(id: anchorId) : $0.moveNoteUp(id: anchorId) }
        scrollTo(anchorId)
    }
}
