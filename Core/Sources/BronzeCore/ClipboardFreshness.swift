import Foundation

/// Tracks external pasteboard changes so capture can trust a clipboard that
/// changed just before the chord (copy-on-select apps expose no other signal).
public struct ClipboardFreshness {
    private var lastSeenCount: Int
    private var ownCounts: Set<Int> = []
    private var lastExternalChange: Date?

    public init(changeCount: Int, now: Date) {
        self.lastSeenCount = changeCount
    }

    public mutating func observe(changeCount: Int, at date: Date) {
        guard changeCount != lastSeenCount else { return }
        lastSeenCount = changeCount
        if !ownCounts.contains(changeCount) {
            lastExternalChange = date
        }
    }

    public mutating func recordOwnWrite(changeCount: Int) {
        ownCounts.insert(changeCount)
    }

    public func isFresh(at date: Date, window: TimeInterval) -> Bool {
        guard let lastExternalChange else { return false }
        return date.timeIntervalSince(lastExternalChange) < window
    }
}
