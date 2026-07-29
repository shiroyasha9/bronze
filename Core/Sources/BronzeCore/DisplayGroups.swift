import Foundation

public struct DisplayGroup: Equatable {
    public let section: Section?
    public let notes: [Note]
}

extension NotesStore {
    public func displayGroups(query: String) -> [DisplayGroup] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let filtering = !trimmed.isEmpty

        func matching(_ notes: [Note]) -> [Note] {
            guard filtering else { return notes }
            return notes.filter { $0.text.localizedCaseInsensitiveContains(trimmed) }
        }

        var groups: [DisplayGroup] = []
        let unsectioned = matching(notes(in: nil))
        if !unsectioned.isEmpty || !filtering {
            groups.append(DisplayGroup(section: nil, notes: unsectioned))
        }
        for section in sections {
            let matches = matching(notes(in: section.id))
            if !matches.isEmpty || !filtering {
                groups.append(DisplayGroup(section: section, notes: matches))
            }
        }
        return groups
    }

    public func listText(ids: [UUID]) -> String {
        orderedNotes(ids: ids)
            .enumerated()
            .map { "\($0.offset + 1). \($0.element.text)" }
            .joined(separator: "\n")
    }

    public func copyText(ids: [UUID]) -> String {
        orderedNotes(ids: ids).map(\.text).joined(separator: "\n\n")
    }

    private func orderedNotes(ids: [UUID]) -> [Note] {
        ids.compactMap { id in notes.first { $0.id == id } }
    }
}
