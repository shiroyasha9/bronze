import BronzeCore
import Foundation
import SwiftUI

enum DropPosition: Equatable {
    case before(UUID)
    case after(UUID)
    case startOfSection(UUID?)
}

enum DropEdge: Equatable {
    case top
    case bottom
}

struct DropIndicator: Equatable {
    var noteId: UUID
    var edge: DropEdge
}

extension AppModel {
    var dragEnabled: Bool { dragDropEnabled && query.isEmpty }

    func dragPayload(for note: Note) -> NoteDragPayload {
        let ids = selectedIds.contains(note.id) ? orderedSelection() : [note.id]
        let payload = NoteDragPayload(noteIds: ids, text: store.copyText(ids: ids))
        activeDragPayload = payload
        return payload
    }

    func handleEndDrop(_ payload: NoteDragPayload) -> Bool {
        if payload.isExternal {
            let position: DropPosition = visibleNotes.last.map { .after($0.id) } ?? .startOfSection(nil)
            return handleDrop(payload, at: position)
        }
        guard let anchor = visibleNotes.last(where: { !payload.noteIds.contains($0.id) }) else { return true }
        return handleDrop(payload, at: .after(anchor.id))
    }

    func performDrop(info: DropInfo, at position: DropPosition) -> Bool {
        withPayload(from: info) { model, payload in
            model.handleDrop(payload, at: position)
        }
    }

    func performEndDrop(info: DropInfo) -> Bool {
        withPayload(from: info) { model, payload in
            model.handleEndDrop(payload)
        }
    }

    private func withPayload(
        from info: DropInfo,
        _ apply: @escaping @MainActor (AppModel, NoteDragPayload) -> Bool
    ) -> Bool {
        guard dragEnabled else { return false }
        if info.hasItemsConforming(to: [.bronzeNotes]), let payload = activeDragPayload {
            activeDragPayload = nil
            return apply(self, payload)
        }
        guard let provider = info.itemProviders(for: [.bronzeNotes, .text]).first else { return false }
        _ = provider.loadTransferable(type: NoteDragPayload.self) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                if case .success(let payload) = result {
                    _ = apply(self, payload)
                }
            }
        }
        return true
    }

    func handleDrop(_ payload: NoteDragPayload, at position: DropPosition) -> Bool {
        dropIndicator = nil
        guard dragEnabled else { return false }
        if payload.isExternal {
            return insertDroppedText(payload.text, at: position)
        }
        let ids = payload.noteIds
        mutate { store in
            switch position {
            case .before(let anchor): store.moveNotes(ids: ids, before: anchor)
            case .after(let anchor): store.moveNotes(ids: ids, after: anchor)
            case .startOfSection(let sectionId): store.moveNotes(ids: ids, toStartOfSection: sectionId)
            }
        }
        selectedIds = ids
        return true
    }

    private func insertDroppedText(_ raw: String, at position: DropPosition) -> Bool {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }
        var created: Note?
        mutate { store in
            switch position {
            case .before(let anchor): created = store.insertNote(text: text, before: anchor)
            case .after(let anchor): created = store.insertNote(text: text, after: anchor)
            case .startOfSection(let sectionId): created = store.insertNote(text: text, atStartOfSection: sectionId)
            }
        }
        guard let created else {
            selectedIds = []
            return false
        }
        selectedIds = [created.id]
        return true
    }
}
