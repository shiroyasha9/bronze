import SwiftUI

enum Bronze {
    static let accent = Color(red: 0.72, green: 0.47, blue: 0.28)
    static let cardFill = Color.primary.opacity(0.05)
    static let cardStroke = Color.primary.opacity(0.07)
    static let selectionStroke = accent
    static let doneText = Color.secondary.opacity(0.6)
    static let sectionHeader = Color.secondary
    static let panelCorner: CGFloat = 16
    static let cardCorner: CGFloat = 12
}

struct PanelBackground: View {
    var body: some View {
        if #available(macOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(Color(nsColor: .windowBackgroundColor).opacity(0.55)),
                    in: .rect(cornerRadius: Bronze.panelCorner)
                )
        } else {
            VisualEffectBackground()
                .overlay(
                    RoundedRectangle(cornerRadius: Bronze.panelCorner)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.28), .white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
