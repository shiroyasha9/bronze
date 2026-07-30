import SwiftUI

private struct ShortcutRow: Identifiable {
    let label: String
    let standard: String?
    let vim: String?
    var id: String { label }

    init(_ label: String, standard: String? = nil, vim: String? = nil) {
        self.label = label
        self.standard = standard
        self.vim = vim
    }
}

private struct ShortcutSection: Identifiable {
    let name: String
    let rows: [ShortcutRow]
    var id: String { name }
}

private let shortcutSections: [ShortcutSection] = [
    ShortcutSection(name: "Capture", rows: [
        ShortcutRow("New note", standard: "⌘N"),
        ShortcutRow("Insert note below / above", vim: "o / O"),
        ShortcutRow("Edit note", standard: "↩", vim: "i"),
    ]),
    ShortcutSection(name: "Navigate", rows: [
        ShortcutRow("Move cursor", standard: "↑ ↓", vim: "j / k"),
        ShortcutRow("Half page down / up", vim: "⌃D / ⌃U"),
        ShortcutRow("First / last note", vim: "gg / G"),
        ShortcutRow("Previous / next section", vim: "{ / }"),
        ShortcutRow("Center selection", vim: "zz"),
    ]),
    ShortcutSection(name: "Select", rows: [
        ShortcutRow("Extend selection", standard: "⇧↑ ⇧↓", vim: "v / V"),
        ShortcutRow("Toggle done", standard: "Space", vim: "x"),
        ShortcutRow("Delete", standard: "⌫", vim: "dd"),
        ShortcutRow("Copy", standard: "⌘C", vim: "y"),
        ShortcutRow("Copy as list", standard: "⌘⇧C"),
        ShortcutRow("Paste as note", vim: "p"),
        ShortcutRow("Dismiss selection / search", standard: "Esc"),
    ]),
    ShortcutSection(name: "Organize", rows: [
        ShortcutRow("Move to section", vim: "m"),
        ShortcutRow("Add section", standard: "⌘⇧N"),
        ShortcutRow("Reorder note down / up", standard: "⌥J / ⌥K"),
    ]),
    ShortcutSection(name: "Panel", rows: [
        ShortcutRow("Show / hide panel", standard: "⌥Space"),
        ShortcutRow("Search", standard: "⌘F", vim: "/"),
        ShortcutRow("Keyboard shortcuts", standard: "⌘/", vim: "?"),
        ShortcutRow("Quit", standard: "⌘Q"),
    ]),
]

struct ShortcutGuideView: View {
    @EnvironmentObject private var model: AppModel
    @State private var scrollIndex = 0

    private let standardWidth: CGFloat = 74
    private let vimWidth: CGFloat = 64

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                header
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(shortcutSections) { section in
                            sectionView(section)
                                .id(section.id)
                        }
                    }
                    .padding(14)
                }
                .scrollIndicators(.never)
            }
            .onChange(of: model.guideScrollStep) { old, new in
                scrollIndex = max(0, min(shortcutSections.count - 1, scrollIndex + (new - old)))
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(shortcutSections[scrollIndex].id, anchor: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Bronze.panelCorner))
        .contentShape(Rectangle())
        .onTapGesture { model.toggleShortcutGuide() }
    }

    private var header: some View {
        HStack {
            Text("Keyboard Shortcuts")
                .font(.headline)
            Spacer()
            Text("Standard")
                .frame(width: standardWidth, alignment: .trailing)
            Text("Vim")
                .frame(width: vimWidth, alignment: .trailing)
        }
        .font(.caption)
        .foregroundStyle(Bronze.sectionHeader)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func sectionView(_ section: ShortcutSection) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(section.name)
                .font(.caption.smallCaps().weight(.semibold))
                .foregroundStyle(Bronze.sectionHeader)
            ForEach(section.rows) { row in
                HStack(spacing: 0) {
                    Text(row.label)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 8)
                    keycapCell(row.standard, width: standardWidth)
                    keycapCell(row.vim, width: vimWidth)
                }
            }
        }
    }

    @ViewBuilder
    private func keycapCell(_ keys: String?, width: CGFloat) -> some View {
        Group {
            if let keys {
                Text(keys)
                    .font(.caption.monospaced())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Bronze.cardFill, in: RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Bronze.cardStroke)
                    )
            } else {
                Text("")
            }
        }
        .frame(width: width, alignment: .trailing)
    }
}
