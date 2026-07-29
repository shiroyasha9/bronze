import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var text = ""
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.tertiary)
                .padding(.top, 1)

            TextField("Add a note or a prompt", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...6)
                .focused(focused)
                .onSubmit(commit)
        }
        .padding(10)
        .background(Bronze.cardFill, in: RoundedRectangle(cornerRadius: Bronze.cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: Bronze.cardCorner)
                .strokeBorder(Bronze.cardStroke, lineWidth: 1)
        )
    }

    private func commit() {
        model.addNote(text: text)
        text = ""
    }
}
