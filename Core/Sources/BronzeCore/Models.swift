import Foundation

public struct Note: Identifiable, Equatable, Codable {
    public var id: UUID
    public var text: String
    public var done: Bool
    public var sectionId: UUID?
    public var projectId: UUID?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        done: Bool = false,
        sectionId: UUID? = nil,
        projectId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.done = done
        self.sectionId = sectionId
        self.projectId = projectId
        // Millisecond precision: exact roundtrip through JSON epoch-ms encoding.
        self.createdAt = Date(
            timeIntervalSince1970: (createdAt.timeIntervalSince1970 * 1000).rounded() / 1000
        )
    }
}

public struct Section: Identifiable, Equatable, Codable {
    public var id: UUID
    public var name: String

    public init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
