import Testing
@testable import BronzeCore

@Suite struct NotesStoreTests {
    @Test func addNoteAppendsToUnsectionedZone() {
        let store = NotesStore()
        let note = store.addNote(text: "capture this")
        #expect(store.notes.count == 1)
        #expect(store.notes[0].id == note.id)
        #expect(store.notes[0].text == "capture this")
        #expect(store.notes[0].sectionId == nil)
        #expect(store.notes[0].done == false)
    }

    @Test func editNoteUpdatesText() {
        let store = NotesStore()
        let note = store.addNote(text: "old")
        store.editNote(id: note.id, text: "new")
        #expect(store.notes[0].text == "new")
    }

    @Test func deleteNoteRemovesIt() {
        let store = NotesStore()
        let a = store.addNote(text: "a")
        let b = store.addNote(text: "b")
        store.deleteNotes(ids: [a.id])
        #expect(store.notes.map(\.text) == ["b"])
        _ = b
    }

    @Test func toggleDoneFlipsState() {
        let store = NotesStore()
        let note = store.addNote(text: "task")
        store.toggleDone(ids: [note.id])
        #expect(store.notes[0].done == true)
        store.toggleDone(ids: [note.id])
        #expect(store.notes[0].done == false)
    }

    @Test func clearCompletedRemovesOnlyDoneNotes() {
        let store = NotesStore()
        let a = store.addNote(text: "done one")
        _ = store.addNote(text: "open one")
        store.toggleDone(ids: [a.id])
        store.clearCompleted()
        #expect(store.notes.map(\.text) == ["open one"])
    }
}

@Suite struct SectionTests {
    @Test func createSectionAppends() {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        #expect(store.sections.map(\.id) == [s.id])
        #expect(store.sections[0].name == "Research")
    }

    @Test func renameSection() {
        let store = NotesStore()
        let s = store.createSection(name: "Old")
        store.renameSection(id: s.id, name: "New")
        #expect(store.sections[0].name == "New")
    }

    @Test func deleteSectionReturnsNotesToUnsectioned() {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        let note = store.addNote(text: "filed")
        store.moveNotes(ids: [note.id], to: s.id)
        store.deleteSection(id: s.id)
        #expect(store.sections.isEmpty)
        #expect(store.notes[0].sectionId == nil)
    }

    @Test func moveNoteToSectionAppendsAtItsEnd() {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        let first = store.addNote(text: "first")
        let second = store.addNote(text: "second")
        store.moveNotes(ids: [first.id], to: s.id)
        store.moveNotes(ids: [second.id], to: s.id)
        #expect(store.notes(in: s.id).map(\.text) == ["first", "second"])
        #expect(store.notes(in: nil).isEmpty)
    }

    @Test func displayOrderIsUnsectionedThenSectionsInOrder() {
        let store = NotesStore()
        let s1 = store.createSection(name: "A")
        let s2 = store.createSection(name: "B")
        let inbox = store.addNote(text: "inbox")
        let a = store.addNote(text: "a")
        let b = store.addNote(text: "b")
        store.moveNotes(ids: [a.id], to: s1.id)
        store.moveNotes(ids: [b.id], to: s2.id)
        #expect(store.displayOrder().map(\.text) == ["inbox", "a", "b"])
        _ = inbox
    }
}

@Suite struct ReorderTests {
    @Test func moveUpSwapsWithinGroup() {
        let store = NotesStore()
        _ = store.addNote(text: "one")
        let two = store.addNote(text: "two")
        store.moveNoteUp(id: two.id)
        #expect(store.notes(in: nil).map(\.text) == ["two", "one"])
    }

    @Test func moveUpAtGroupTopJoinsEndOfPreviousGroup() {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        _ = store.addNote(text: "inbox note")
        let filed = store.addNote(text: "filed note")
        store.moveNotes(ids: [filed.id], to: s.id)
        store.moveNoteUp(id: filed.id)
        #expect(store.notes(in: nil).map(\.text) == ["inbox note", "filed note"])
        #expect(store.notes(in: s.id).isEmpty)
    }

    @Test func moveDownAtGroupBottomJoinsTopOfNextGroup() {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        let inbox = store.addNote(text: "inbox note")
        let filed = store.addNote(text: "already filed")
        store.moveNotes(ids: [filed.id], to: s.id)
        store.moveNoteDown(id: inbox.id)
        #expect(store.notes(in: nil).isEmpty)
        #expect(store.notes(in: s.id).map(\.text) == ["inbox note", "already filed"])
    }

    @Test func insertNoteBelowStaysInGroupAndPosition() {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        let a = store.addNote(text: "a")
        let c = store.addNote(text: "c")
        store.moveNotes(ids: [a.id, c.id], to: s.id)
        let b = store.insertNote(text: "b", after: a.id)
        #expect(store.notes(in: s.id).map(\.text) == ["a", "b", "c"])
        #expect(b?.sectionId == s.id)
    }

    @Test func insertNoteAbovePlacesBeforeAnchor() {
        let store = NotesStore()
        let a = store.addNote(text: "a")
        let b = store.insertNote(text: "b", before: a.id)
        #expect(store.notes(in: nil).map(\.text) == ["b", "a"])
        #expect(b?.sectionId == nil)
    }

    @Test func moveUpAtVeryTopIsNoOp() {
        let store = NotesStore()
        let only = store.addNote(text: "only")
        store.moveNoteUp(id: only.id)
        #expect(store.notes(in: nil).map(\.text) == ["only"])
    }
}
