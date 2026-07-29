import SwiftUI

struct ToastMessage: Equatable {
    let id = UUID()
    let text: String
}

struct ToastContent: View {
    let message: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
            Text(message)
        }
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .fixedSize()
    }
}

struct ToastLabel: View {
    let message: String

    var body: some View {
        if #available(macOS 26.0, *) {
            ToastContent(message: message)
                .glassEffect(.regular, in: .capsule)
        } else {
            ToastContent(message: message)
                .background(.regularMaterial, in: Capsule())
        }
    }
}
