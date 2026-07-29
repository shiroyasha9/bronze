import Foundation
import Testing
@testable import BronzeCore

@Suite struct SearchTests {
    @Test func emptyQueryShowsAllGroupsIncludingEmptySections() {
        let store = NotesStore()
        let s = store.createSection(name: "Empty")
        _ = store.addNote(text: "inbox")
        let groups = store.displayGroups(query: "")
        #expect(groups.count == 2)
        #expect(groups[0].section == nil)
        #expect(groups[0].notes.map(\.text) == ["inbox"])
        #expect(groups[1].section?.id == s.id)
        #expect(groups[1].notes.isEmpty)
    }

    @Test func filterHidesNonMatchingNotesAndEmptySections() {
        let store = NotesStore()
        let s1 = store.createSection(name: "Hit")
        let s2 = store.createSection(name: "Miss")
        let hit = store.addNote(text: "TOML config format")
        let miss = store.addNote(text: "unrelated")
        store.moveNotes(ids: [hit.id], to: s1.id)
        store.moveNotes(ids: [miss.id], to: s2.id)
        let groups = store.displayGroups(query: "toml")
        #expect(groups.count == 1)
        #expect(groups[0].section?.id == s1.id)
        #expect(groups[0].notes.map(\.text) == ["TOML config format"])
    }

    @Test func filterMatchesCaseInsensitiveSubstring() {
        let store = NotesStore()
        _ = store.addNote(text: "Negation in inherited configs")
        let groups = store.displayGroups(query: "INHERIT")
        #expect(groups.count == 1)
        #expect(groups[0].notes.count == 1)
    }

    @Test func unsectionedGroupOmittedWhenEmptyDuringFilter() {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        let filed = store.addNote(text: "filed match")
        store.moveNotes(ids: [filed.id], to: s.id)
        let groups = store.displayGroups(query: "match")
        #expect(groups.count == 1)
        #expect(groups[0].section?.id == s.id)
    }
}

@Suite struct CopyAsListTests {
    @Test func numbersNotesInGivenOrder() {
        let store = NotesStore()
        let a = store.addNote(text: "How should migrations work?")
        let b = store.addNote(text: "Should plugins own schemas?")
        let text = store.listText(ids: [b.id, a.id])
        #expect(text == "1. Should plugins own schemas?\n2. How should migrations work?")
    }

    @Test func skipsUnknownIds() {
        let store = NotesStore()
        let a = store.addNote(text: "only")
        let text = store.listText(ids: [a.id, UUID()])
        #expect(text == "1. only")
    }

    @Test func singleNoteCopyIsRawText() {
        let store = NotesStore()
        let a = store.addNote(text: "**bold** fragment")
        #expect(store.copyText(ids: [a.id]) == "**bold** fragment")
    }

    @Test func multiNoteCopyJoinsWithBlankLine() {
        let store = NotesStore()
        let a = store.addNote(text: "first")
        let b = store.addNote(text: "second")
        #expect(store.copyText(ids: [a.id, b.id]) == "first\n\nsecond")
    }
}
