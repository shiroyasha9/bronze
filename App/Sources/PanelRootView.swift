import BronzeCore
import SwiftUI

struct PanelRootView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var searchFocused: Bool
    @FocusState private var composerFocused: Bool

    var body: some View {
        VStack(spacing: 12) {
            header
            notesList
            ComposerView(focused: $composerFocused)
        }
        .padding(12)
        .ignoresSafeArea(.container, edges: .top)
        .frame(minWidth: 300, minHeight: 400)
        .background(VisualEffectBackground().ignoresSafeArea())
        .environment(\.searchFocus, $searchFocused)
        .onChange(of: model.searchRequest) { _, _ in searchFocused = true }
        .onChange(of: model.composerRequest) { _, _ in composerFocused = true }
    }

    private var header: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $model.query)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .onKeyPress(.escape) {
                        model.query = ""
                        searchFocused = false
                        return .handled
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Bronze.cardFill, in: Capsule())

            Menu {
                Button("Add Section…") { model.promptNewSection() }
                Button("Clear Completed") { model.mutate { $0.clearCompleted() } }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private var notesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8, pinnedViews: []) {
                    ForEach(Array(model.groups.enumerated()), id: \.offset) { _, group in
                        if let section = group.section {
                            SectionHeaderView(section: section)
                        }
                        ForEach(group.notes) { note in
                            NoteCardView(note: note)
                                .id(note.id)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            .onChange(of: model.scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo(target.id, anchor: target.anchor)
                }
                model.scrollTarget = nil
            }
        }
    }
}

private struct SearchFocusKey: EnvironmentKey {
    static let defaultValue: FocusState<Bool>.Binding? = nil
}

extension EnvironmentValues {
    var searchFocus: FocusState<Bool>.Binding? {
        get { self[SearchFocusKey.self] }
        set { self[SearchFocusKey.self] = newValue }
    }
}
