import Foundation

public final class NotesStore {
    public private(set) var notes: [Note]
    public private(set) var sections: [Section]

    public init(notes: [Note] = [], sections: [Section] = []) {
        self.notes = notes
        self.sections = sections
    }

    @discardableResult
    public func addNote(text: String, sectionId: UUID? = nil) -> Note {
        let note = Note(text: text, sectionId: sectionId)
        notes.append(note)
        return note
    }

    public func editNote(id: UUID, text: String) {
        guard let i = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[i].text = text
    }

    public func deleteNotes(ids: Set<UUID>) {
        notes.removeAll { ids.contains($0.id) }
    }

    public func toggleDone(ids: Set<UUID>) {
        for i in notes.indices where ids.contains(notes[i].id) {
            notes[i].done.toggle()
        }
    }

    public func clearCompleted() {
        notes.removeAll(where: \.done)
    }

    public func clearUnsectioned() {
        notes.removeAll { $0.sectionId == nil }
    }

    public func clearAllNotes() {
        notes.removeAll()
    }

    public func clearEverything() {
        notes.removeAll()
        sections.removeAll()
    }

    @discardableResult
    public func createSection(name: String) -> Section {
        let section = Section(name: name)
        sections.append(section)
        return section
    }

    public func renameSection(id: UUID, name: String) {
        guard let i = sections.firstIndex(where: { $0.id == id }) else { return }
        sections[i].name = name
    }

    public func deleteSection(id: UUID) {
        sections.removeAll { $0.id == id }
        for i in notes.indices where notes[i].sectionId == id {
            notes[i].sectionId = nil
        }
    }

    public func moveNotes(ids: Set<UUID>, to sectionId: UUID?) {
        let moved = displayOrder().filter { ids.contains($0.id) }
        notes.removeAll { ids.contains($0.id) }
        for var note in moved {
            note.sectionId = sectionId
            notes.append(note)
        }
    }

    public func notes(in sectionId: UUID?) -> [Note] {
        notes.filter { $0.sectionId == sectionId }
    }

    /// Visible sequence: unsectioned zone first, then each section in order.
    public func displayOrder() -> [Note] {
        notes(in: nil) + sections.flatMap { notes(in: $0.id) }
    }

    public func moveNoteUp(id: UUID) {
        let order = displayOrder()
        guard let pos = order.firstIndex(where: { $0.id == id }) else { return }
        guard pos > 0 else { return }
        let prev = order[pos - 1]
        if prev.sectionId == order[pos].sectionId {
            swapInArray(id, prev.id)
        } else {
            moveNotes(ids: [id], to: prev.sectionId)
        }
    }

    public func moveNoteDown(id: UUID) {
        let order = displayOrder()
        guard let pos = order.firstIndex(where: { $0.id == id }) else { return }
        guard pos < order.count - 1 else { return }
        let next = order[pos + 1]
        if next.sectionId == order[pos].sectionId {
            swapInArray(id, next.id)
        } else {
            prependNote(id, to: next.sectionId)
        }
    }

    public func moveNotes(ids: [UUID], before anchorId: UUID) {
        moveNotes(ids: ids, anchorId: anchorId, offset: 0)
    }

    public func moveNotes(ids: [UUID], after anchorId: UUID) {
        moveNotes(ids: ids, anchorId: anchorId, offset: 1)
    }

    public func moveNotes(ids: [UUID], toStartOfSection sectionId: UUID?) {
        let idSet = Set(ids)
        var moved = displayOrder().filter { idSet.contains($0.id) }
        guard !moved.isEmpty else { return }
        notes.removeAll { idSet.contains($0.id) }
        for i in moved.indices { moved[i].sectionId = sectionId }
        notes.insert(contentsOf: moved, at: startIndex(of: sectionId))
    }

    @discardableResult
    public func insertNote(text: String, atStartOfSection sectionId: UUID?) -> Note {
        let note = Note(text: text, sectionId: sectionId)
        notes.insert(note, at: startIndex(of: sectionId))
        return note
    }

    private func moveNotes(ids: [UUID], anchorId: UUID, offset: Int) {
        let idSet = Set(ids)
        guard !idSet.contains(anchorId) else { return }
        var moved = displayOrder().filter { idSet.contains($0.id) }
        guard !moved.isEmpty else { return }
        guard notes.contains(where: { $0.id == anchorId }) else { return }
        notes.removeAll { idSet.contains($0.id) }
        guard let i = notes.firstIndex(where: { $0.id == anchorId }) else { return }
        for j in moved.indices { moved[j].sectionId = notes[i].sectionId }
        notes.insert(contentsOf: moved, at: i + offset)
    }

    private func startIndex(of sectionId: UUID?) -> Int {
        notes.firstIndex { $0.sectionId == sectionId } ?? notes.count
    }

    @discardableResult
    public func insertNote(text: String, after anchorId: UUID) -> Note? {
        insertNote(text: text, anchorId: anchorId, offset: 1)
    }

    @discardableResult
    public func insertNote(text: String, before anchorId: UUID) -> Note? {
        insertNote(text: text, anchorId: anchorId, offset: 0)
    }

    private func insertNote(text: String, anchorId: UUID, offset: Int) -> Note? {
        guard let i = notes.firstIndex(where: { $0.id == anchorId }) else { return nil }
        let note = Note(text: text, sectionId: notes[i].sectionId)
        notes.insert(note, at: i + offset)
        return note
    }

    private func swapInArray(_ a: UUID, _ b: UUID) {
        guard let i = notes.firstIndex(where: { $0.id == a }),
              let j = notes.firstIndex(where: { $0.id == b }) else { return }
        notes.swapAt(i, j)
    }

    private func prependNote(_ id: UUID, to sectionId: UUID?) {
        guard let i = notes.firstIndex(where: { $0.id == id }) else { return }
        var note = notes.remove(at: i)
        note.sectionId = sectionId
        notes.insert(note, at: 0)
    }
}
