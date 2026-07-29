import AppKit
import BronzeCore
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var revision = 0
    @Published var query = ""
    @Published var selectedIds: [UUID] = []
    @Published var editingId: UUID?
    @Published var scrollTarget: ScrollTarget?
    @Published var visualMode = false
    @Published var searchRequest = 0
    @Published var composerRequest = 0

    private(set) var store: NotesStore
    private let fileURL: URL
    private var saveTask: Task<Void, Never>?

    init(fileURL: URL = AppModel.defaultFileURL) {
        self.fileURL = fileURL
        self.store = (try? Persistence.load(from: fileURL)) ?? NotesStore()
    }

    nonisolated static var defaultFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Bronze/notes.json")
    }

    var groups: [DisplayGroup] { store.displayGroups(query: query) }
    var visibleNotes: [Note] { groups.flatMap(\.notes) }

    func mutate(_ operation: (NotesStore) -> Void) {
        operation(store)
        revision += 1
        scheduleSave()
    }

    func addNote(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        mutate { $0.addNote(text: trimmed) }
    }

    func capture(text: String) {
        addNote(text: text)
    }

    func copySelection() {
        guard !selectedIds.isEmpty else { return }
        setPasteboard(store.copyText(ids: selectedIds))
    }

    func copySelectionAsList() {
        guard !selectedIds.isEmpty else { return }
        setPasteboard(store.listText(ids: orderedSelection()))
    }

    func deleteSelection() {
        guard !selectedIds.isEmpty else { return }
        let ids = Set(selectedIds)
        selectNeighborAfterRemoval(of: ids)
        mutate { $0.deleteNotes(ids: ids) }
    }

    func toggleDoneSelection() {
        guard !selectedIds.isEmpty else { return }
        mutate { $0.toggleDone(ids: Set(selectedIds)) }
    }

    /// Selection ordered by on-screen position, so Copy as List follows display order.
    private func orderedSelection() -> [UUID] {
        let selected = Set(selectedIds)
        return visibleNotes.map(\.id).filter(selected.contains)
    }

    private func selectNeighborAfterRemoval(of ids: Set<UUID>) {
        let visible = visibleNotes.map(\.id)
        let after = visible.drop { !ids.contains($0) }.first { !ids.contains($0) }
        let before = visible.last { id in
            !ids.contains(id) && visible.firstIndex(of: id)! < (visible.firstIndex(where: ids.contains) ?? 0)
        }
        selectedIds = [after ?? before].compactMap { $0 }
    }

    private func setPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        try? Persistence.save(store, to: fileURL)
    }
}
