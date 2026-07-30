import AppKit
import BronzeCore
import Combine
import Foundation
import SwiftUI

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
    @Published var dragDropEnabled: Bool {
        didSet { UserDefaults.standard.set(dragDropEnabled, forKey: "dragDropEnabled") }
    }
    @Published var pinToForeground: Bool {
        didSet { UserDefaults.standard.set(pinToForeground, forKey: "pinToForeground") }
    }
    @Published var dropIndicator: DropIndicator?
    @Published var toast: ToastMessage?
    var activeDragPayload: NoteDragPayload?
    private var dropIndicatorExpiry: Task<Void, Never>?
    private var toastExpiry: Task<Void, Never>?

    /// dropExited is unreliable when a drag ends outside any target, so the
    /// indicator is cleared as soon as the mouse button releases.
    func showDropIndicator(_ indicator: DropIndicator) {
        guard NSEvent.pressedMouseButtons != 0 else { return }
        dropIndicator = indicator
        guard dropIndicatorExpiry == nil else { return }
        dropIndicatorExpiry = Task { [weak self] in
            while NSEvent.pressedMouseButtons != 0, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(60))
            }
            self?.dropIndicator = nil
            self?.dropIndicatorExpiry = nil
        }
    }

    private(set) var store: NotesStore
    private let fileURL: URL
    private var saveTask: Task<Void, Never>?
    var pasteboardTracker: PasteboardTracker?

    init(fileURL: URL = AppModel.defaultFileURL) {
        self.fileURL = fileURL
        self.store = (try? Persistence.load(from: fileURL)) ?? NotesStore()
        self.dragDropEnabled = UserDefaults.standard.object(forKey: "dragDropEnabled") as? Bool ?? true
        self.pinToForeground = UserDefaults.standard.bool(forKey: "pinToForeground")
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

    func addNote(text: String, to sectionId: UUID? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var added: Note?
        mutate { added = $0.addNote(text: trimmed, sectionId: sectionId) }
        if let added {
            scrollTarget = ScrollTarget(id: added.id, anchor: .bottom)
        }
    }

    var composerTargetSectionId: UUID? {
        guard let anchorId else { return nil }
        return store.notes.first { $0.id == anchorId }?.sectionId
    }

    func sectionName(for id: UUID?) -> String {
        guard let id else { return "Inbox" }
        return store.sections.first { $0.id == id }?.name ?? "Inbox"
    }

    func capture(text: String) {
        addNote(text: text)
    }

    func copySelection() {
        guard !selectedIds.isEmpty else { return }
        setPasteboard(store.copyText(ids: selectedIds))
        showToast("Copied")
    }

    func copySelectionAsList() {
        guard !selectedIds.isEmpty else { return }
        setPasteboard(store.listText(ids: orderedSelection()))
        showToast("Copied as List")
    }

    func showToast(_ text: String) {
        let message = ToastMessage(text: text)
        withAnimation(.easeOut(duration: 0.15)) { toast = message }
        toastExpiry?.cancel()
        toastExpiry = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) { self?.toast = nil }
        }
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
    func orderedSelection() -> [UUID] {
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
        pasteboardTracker?.noteOwnWrite()
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
