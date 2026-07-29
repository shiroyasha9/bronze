import BronzeCore
import SwiftUI

struct NoteCardView: View {
    @EnvironmentObject private var model: AppModel
    let note: Note
    @State private var draft = ""
    @FocusState private var editorFocused: Bool

    private var isSelected: Bool { model.selectedIds.contains(note.id) }
    private var isEditing: Bool { model.editingId == note.id }

    var body: some View {
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
    @State private var renaming = false
    @State private var draft = ""

    var body: some View {
        HStack(spacing: 8) {
            if renaming {
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, weight: .semibold))
                    .onSubmit {
                        let name = draft.trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty {
                            model.mutate { $0.renameSection(id: section.id, name: name) }
                        }
                        renaming = false
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
        .contextMenu {
            Button("Rename") {
                draft = section.name
                renaming = true
            }
            Button("Delete Section", role: .destructive) {
                model.mutate { $0.deleteSection(id: section.id) }
            }
        }
    }
}
