import AppKit
import BronzeCore

@MainActor
final class PasteboardTracker {
    static let freshnessWindow: TimeInterval = 5

    private var freshness: ClipboardFreshness
    private var timer: Timer?

    init() {
        freshness = ClipboardFreshness(
            changeCount: NSPasteboard.general.changeCount,
            now: Date()
        )
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func poll() {
        freshness.observe(changeCount: NSPasteboard.general.changeCount, at: Date())
    }

    func noteOwnWrite() {
        freshness.recordOwnWrite(changeCount: NSPasteboard.general.changeCount)
    }

    var freshExternalText: String? {
        poll()
        guard freshness.isFresh(at: Date(), window: Self.freshnessWindow) else { return nil }
        return NSPasteboard.general.string(forType: .string)
    }
}
