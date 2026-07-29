import CoreTransferable
import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let bronzeNotes = UTType(exportedAs: "tech.teensy.bronze.notes")
}

struct NoteDragPayload: Codable, Transferable {
    var noteIds: [UUID]
    var text: String

    var isExternal: Bool { noteIds.isEmpty }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .bronzeNotes)
        ProxyRepresentation(
            exporting: \.text,
            importing: { NoteDragPayload(noteIds: [], text: $0) }
        )
    }
}
