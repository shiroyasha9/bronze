import Foundation
import Testing
@testable import BronzeCore

@Suite struct PersistenceTests {
    private func tempFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("bronze-test-\(UUID().uuidString).json")
    }

    @Test func roundtripPreservesNotesAndSections() throws {
        let store = NotesStore()
        let s = store.createSection(name: "Research")
        let a = store.addNote(text: "**bold** note")
        store.moveNotes(ids: [a.id], to: s.id)
        store.toggleDone(ids: [a.id])
        _ = store.addNote(text: "inbox note")

        let url = tempFile()
        try Persistence.save(store, to: url)
        let loaded = try Persistence.load(from: url)

        #expect(loaded.notes == store.notes)
        #expect(loaded.sections == store.sections)
    }

    @Test func savedFileCarriesSchemaVersion() throws {
        let store = NotesStore()
        _ = store.addNote(text: "x")
        let url = tempFile()
        try Persistence.save(store, to: url)

        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        #expect(json?["version"] as? Int == 1)
    }

    @Test func loadFromMissingFileReturnsEmptyStore() throws {
        let loaded = try Persistence.load(from: tempFile())
        #expect(loaded.notes.isEmpty)
        #expect(loaded.sections.isEmpty)
    }
}
