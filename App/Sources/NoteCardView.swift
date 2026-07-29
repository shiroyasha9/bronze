import BronzeCore
import SwiftUI

struct NoteCardView: View {
    @EnvironmentObject private var model: AppModel
    let note: Note
    @State private var draft = ""
    @FocusState private var editorFocused: Bool

    @State private var cardHeight: CGFloat = 0

    private var isSelected: Bool { model.selectedIds.contains(note.id) }
    private var isEditing: Bool { model.editingId == note.id }

    var body: some View {
        if model.dragEnabled {
            card
                .draggable(model.dragPayload(for: note)) {
                    DragPreviewChip(
                        title: note.text.components(separatedBy: .newlines).first ?? "",
                        count: model.selectedIds.contains(note.id) ? model.selectedIds.count : 1
                    )
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.onChange(of: geo.size.height, initial: true) { _, h in
                            cardHeight = h
                        }
                    }
                )
                .onDrop(
                    of: [.bronzeNotes, .text],
                    delegate: NoteCardDropDelegate(
                        model: model,
                        noteId: note.id,
                        height: { cardHeight }
                    )
                )
                .overlay(alignment: .top) {
                    if model.dropIndicator == DropIndicator(noteId: note.id, edge: .top) {
                        DropIndicatorLine().offset(y: -5)
                    }
                }
                .overlay(alignment: .bottom) {
                    if model.dropIndicator == DropIndicator(noteId: note.id, edge: .bottom) {
                        DropIndicatorLine().offset(y: 5)
                    }
                }
        } else {
            card
        }
    }

    private var card: some View {
        HStack(alignment: .top, spacing: 10) {
            checkbox
            if isEditing {
                editor
            } else {
                noteText
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Bronze.cardFill, in: RoundedRectangle(cornerRadius: Bronze.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Bronze.cardCorner)
                .strokeBorder(
                    isSelected ? Bronze.selectionStroke : Bronze.cardStroke,
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: Bronze.cardCorner))
        .onTapGesture {
            model.select(note.id, extend: NSEvent.modifierFlags.contains(.command)
                || NSEvent.modifierFlags.contains(.shift))
        }
        .contextMenu { contextMenuItems }
    }

    private var checkbox: some View {
        Button {
            model.mutate { $0.toggleDone(ids: [note.id]) }
        } label: {
            Image(systemName: note.done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(note.done ? Bronze.accent : Color.secondary)
        }
        .buttonStyle(.plain)
    }

    private var noteText: some View {
        Text(model.attributedText(for: note))
            .lineLimit(3)
            .strikethrough(note.done)
            .foregroundStyle(note.done ? Bronze.doneText : Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var editor: some View {
        TextField("", text: $draft, axis: .vertical)
            .textFieldStyle(.plain)
            .focused($editorFocused)
            .onAppear {
                draft = note.text
                editorFocused = true
            }
            .onSubmit { commitEdit() }
            .onKeyPress(.escape) {
                model.editingId = nil
                if note.text.isEmpty {
                    model.mutate { $0.deleteNotes(ids: [note.id]) }
                }
                return .handled
            }
    }

    private func commitEdit() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        model.editingId = nil
        if !text.isEmpty {
            model.mutate { $0.editNote(id: note.id, text: text) }
        } else if note.text.isEmpty {
            model.mutate { $0.deleteNotes(ids: [note.id]) }
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Copy") { model.selectIfUnselected(note.id); model.copySelection() }
            .keyboardShortcut("c")
        Button("Copy as List") { model.selectIfUnselected(note.id); model.copySelectionAsList() }
            .keyboardShortcut("c", modifiers: [.shift, .command])
        Button(note.done ? "Mark as Not Done" : "Mark as Done") {
            model.selectIfUnselected(note.id)
            model.toggleDoneSelection()
        }
        Divider()
        Button("Edit") { model.editingId = note.id }
        Menu("Move to") {
            Button("No Section") { model.moveSelection(note.id, to: nil) }
            ForEach(model.store.sections) { section in
                Button(section.name) { model.moveSelection(note.id, to: section.id) }
            }
            Divider()
            Button("New Section…") { model.promptNewSection(moving: note.id) }
        }
        Divider()
        Button("Delete", role: .destructive) {
            model.selectIfUnselected(note.id)
            model.deleteSelection()
        }
    }
}

struct SectionHeaderView: View {
    @EnvironmentObject private var model: AppModel
    let section: BronzeCore.Section
    @State private var isRenaming = false
    @State private var draft = ""
    @State private var isDropTargeted = false

    var body: some View {
        HStack(spacing: 8) {
            if isRenaming {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, weight: .semibold))
                    .onSubmit {
                        let name = draft.trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty {
                            model.mutate { $0.renameSection(id: section.id, name: name) }
                        }
                        isRenaming = false
                    }
            } else {
                Text(section.name.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .kerning(0.8)
                    .foregroundStyle(Bronze.sectionHeader)
            }
            Rectangle()
                .fill(Bronze.cardStroke)
                .frame(height: 1)
        }
        .padding(.top, 8)
        .background(
            isDropTargeted ? Bronze.accent.opacity(0.12) : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .contentShape(Rectangle())
        .onDrop(
            of: [.bronzeNotes, .text],
            delegate: ZoneDropDelegate(model: model, targeted: $isDropTargeted) { model, info in
                model.performDrop(info: info, at: .startOfSection(section.id))
            }
        )
        .contextMenu {
            Button("Rename") {
                draft = section.name
                isRenaming = true
            }
            Button("Delete Section", role: .destructive) {
                model.mutate { $0.deleteSection(id: section.id) }
            }
        }
    }
}

struct DragPreviewChip: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: count > 1 ? "square.stack" : "note.text")
                .font(.system(size: 11))
                .foregroundStyle(Bronze.accent)
            Text(count > 1 ? "\(count) notes" : title)
                .font(.system(size: 12))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: 220)
        .background(Color(nsColor: .windowBackgroundColor), in: Capsule())
        .overlay(Capsule().strokeBorder(Bronze.accent.opacity(0.5), lineWidth: 1))
    }
}

struct DropIndicatorLine: View {
    var body: some View {
        Capsule()
            .fill(Bronze.accent)
            .frame(height: 2)
            .padding(.horizontal, 2)
            .allowsHitTesting(false)
    }
}

struct NoteCardDropDelegate: DropDelegate {
    let model: AppModel
    let noteId: UUID
    let height: () -> CGFloat

    func validateDrop(info: DropInfo) -> Bool {
        MainActor.assumeIsolated { model.dragEnabled }
    }

    func dropEntered(info: DropInfo) {
        showIndicator(info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        showIndicator(info)
        let isInternalDrag = info.hasItemsConforming(to: [.bronzeNotes])
        return DropProposal(operation: isInternalDrag ? .move : .copy)
    }

    func dropExited(info: DropInfo) {
        MainActor.assumeIsolated {
            if model.dropIndicator?.noteId == noteId { model.dropIndicator = nil }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        let position: DropPosition = edge(for: info) == .top ? .before(noteId) : .after(noteId)
        return MainActor.assumeIsolated {
            model.dropIndicator = nil
            return model.performDrop(info: info, at: position)
        }
    }

    private func showIndicator(_ info: DropInfo) {
        let indicator = DropIndicator(noteId: noteId, edge: edge(for: info))
        MainActor.assumeIsolated { model.showDropIndicator(indicator) }
    }

    private func edge(for info: DropInfo) -> DropEdge {
        info.location.y < height() / 2 ? .top : .bottom
    }
}

struct ZoneDropDelegate: DropDelegate {
    let model: AppModel
    @Binding var targeted: Bool
    let perform: @MainActor (AppModel, DropInfo) -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        MainActor.assumeIsolated { model.dragEnabled }
    }

    func dropEntered(info: DropInfo) {
        targeted = true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        let isInternalDrag = info.hasItemsConforming(to: [.bronzeNotes])
        return DropProposal(operation: isInternalDrag ? .move : .copy)
    }

    func dropExited(info: DropInfo) {
        targeted = false
    }

    func performDrop(info: DropInfo) -> Bool {
        targeted = false
        return MainActor.assumeIsolated { perform(model, info) }
    }
}
