import Foundation
import Testing
@testable import BronzeCore

@Suite struct ClipboardFreshnessTests {
    @Test func changeWithinWindowIsFresh() {
        var tracker = ClipboardFreshness(changeCount: 1, now: Date(timeIntervalSince1970: 0))
        tracker.observe(changeCount: 2, at: Date(timeIntervalSince1970: 10))
        #expect(tracker.isFresh(at: Date(timeIntervalSince1970: 15), window: 10))
    }

    @Test func changeOutsideWindowIsStale() {
        var tracker = ClipboardFreshness(changeCount: 1, now: Date(timeIntervalSince1970: 0))
        tracker.observe(changeCount: 2, at: Date(timeIntervalSince1970: 10))
        #expect(!tracker.isFresh(at: Date(timeIntervalSince1970: 25), window: 10))
    }

    @Test func noChangeEverIsStale() {
        var tracker = ClipboardFreshness(changeCount: 1, now: Date(timeIntervalSince1970: 0))
        tracker.observe(changeCount: 1, at: Date(timeIntervalSince1970: 5))
        #expect(!tracker.isFresh(at: Date(timeIntervalSince1970: 6), window: 10))
    }

    @Test func ownWritesAreIgnored() {
        var tracker = ClipboardFreshness(changeCount: 1, now: Date(timeIntervalSince1970: 0))
        tracker.recordOwnWrite(changeCount: 2)
        tracker.observe(changeCount: 2, at: Date(timeIntervalSince1970: 5))
        #expect(!tracker.isFresh(at: Date(timeIntervalSince1970: 6), window: 10))
    }

    @Test func externalChangeAfterOwnWriteIsFresh() {
        var tracker = ClipboardFreshness(changeCount: 1, now: Date(timeIntervalSince1970: 0))
        tracker.recordOwnWrite(changeCount: 2)
        tracker.observe(changeCount: 3, at: Date(timeIntervalSince1970: 5))
        #expect(tracker.isFresh(at: Date(timeIntervalSince1970: 6), window: 10))
    }
}
