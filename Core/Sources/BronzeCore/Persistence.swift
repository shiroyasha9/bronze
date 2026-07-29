import Foundation

public enum Persistence {
    public static let schemaVersion = 1

    private struct Snapshot: Codable {
        var version: Int
        var notes: [Note]
        var sections: [Section]
    }

    public static func save(_ store: NotesStore, to url: URL) throws {
        let snapshot = Snapshot(version: schemaVersion, notes: store.notes, sections: store.sections)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(snapshot)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    public static func load(from url: URL) throws -> NotesStore {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return NotesStore()
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let snapshot = try decoder.decode(Snapshot.self, from: Data(contentsOf: url))
        return NotesStore(notes: snapshot.notes, sections: snapshot.sections)
    }
}
