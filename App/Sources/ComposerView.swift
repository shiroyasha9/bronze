import BronzeCore
import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var text = ""
    @State private var overrideSectionId: UUID?
    @State private var highlightedIndex: Int?
    @State private var popupDismissed = false
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.tertiary)
                .padding(.top, 1)

            TextField("Add a note or a prompt", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .focused(focused)
                .onSubmit(commit)
                .onKeyPress(.escape) {
                    if popupVisible {
                        popupDismissed = true
                        highlightedIndex = nil
                        return .handled
                    }
                    focused.wrappedValue = false
                    return .handled
                }
                .onKeyPress(.upArrow) { movePopupHighlight(-1) }
                .onKeyPress(.downArrow) { movePopupHighlight(1) }
                .onKeyPress(.tab) {
                    guard popupVisible else { return .ignored }
                    confirm(suggestions[highlightedIndex ?? 0])
                    return .handled
                }
                .onKeyPress(.return) {
                    guard popupVisible, let index = highlightedIndex else { return .ignored }
                    confirm(suggestions[index])
                    return .handled
                }

            if focused.wrappedValue || !text.isEmpty {
                Text(destinationName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 3)
            }
        }
        .padding(10)
        .background(Bronze.cardFill, in: RoundedRectangle(cornerRadius: Bronze.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Bronze.cardCorner)
                .strokeBorder(Bronze.cardStroke, lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            if popupVisible {
                suggestionPopup
                    .frame(height: 0, alignment: .bottom)
                    .offset(y: -6)
            }
        }
        .onChange(of: text) { _, newValue in
            if SectionTokenParser.activeToken(in: newValue) == nil {
                popupDismissed = false
                highlightedIndex = nil
            }
        }
        .onChange(of: focused.wrappedValue) { _, isFocused in
            if !isFocused, text.isEmpty { overrideSectionId = nil }
        }
        .onChange(of: suggestions.count) { _, count in
            guard let index = highlightedIndex else { return }
            highlightedIndex = count == 0 ? nil : min(index, count - 1)
        }
    }

    private var activeToken: SectionTokenParser.Token? {
        SectionTokenParser.activeToken(in: text)
    }

    private var suggestions: [BronzeCore.Section] {
        guard let token = activeToken else { return [] }
        return Array(
            SectionTokenParser.matches(fragment: token.fragment, sections: model.store.sections)
                .prefix(5)
        )
    }

    private var popupVisible: Bool {
        focused.wrappedValue && !popupDismissed && activeToken != nil && !suggestions.isEmpty
    }

    private var destinationName: String {
        if let overrideSectionId { return model.sectionName(for: overrideSectionId) }
        if !popupDismissed,
           let resolved = SectionTokenParser.resolveOnCommit(text: text, sections: model.store.sections) {
            return resolved.section.name
        }
        return model.sectionName(for: model.composerTargetSectionId)
    }

    private var suggestionPopup: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, section in
                Text(section.name)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        index == highlightedIndex ? Bronze.accent.opacity(0.25) : .clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { confirm(section) }
            }
        }
        .padding(6)
        .frame(width: 220, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Bronze.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Bronze.cardCorner)
                .strokeBorder(Bronze.cardStroke, lineWidth: 1)
        )
    }

    private func movePopupHighlight(_ delta: Int) -> KeyPress.Result {
        guard popupVisible else { return .ignored }
        let count = suggestions.count
        guard count > 0 else { return .ignored }
        let current = highlightedIndex ?? (delta > 0 ? -1 : count)
        highlightedIndex = (current + delta + count) % count
        return .handled
    }

    private func confirm(_ section: BronzeCore.Section) {
        guard let token = activeToken else { return }
        text = SectionTokenParser.strip(token, from: text)
        overrideSectionId = section.id
        highlightedIndex = nil
    }

    private func commit() {
        var noteText = text
        var target = overrideSectionId ?? model.composerTargetSectionId
        if overrideSectionId == nil, !popupDismissed,
           let resolved = SectionTokenParser.resolveOnCommit(text: text, sections: model.store.sections) {
            target = resolved.section.id
            noteText = resolved.cleanedText
        }
        model.addNote(text: noteText, to: target)
        text = ""
        overrideSectionId = nil
        highlightedIndex = nil
        popupDismissed = false
    }
}
