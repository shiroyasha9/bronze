import Foundation
import Testing
@testable import BronzeCore

@Suite struct ActiveTokenTests {
    @Test func tokenAtEndOfText() {
        let token = SectionTokenParser.activeToken(in: "buy milk #gro")
        #expect(token?.fragment == "gro")
    }

    @Test func tokenAtStartOfText() {
        let token = SectionTokenParser.activeToken(in: "#res note")
        #expect(token?.fragment == "res")
    }

    @Test func lastTokenWins() {
        let token = SectionTokenParser.activeToken(in: "call #a about #res")
        #expect(token?.fragment == "res")
    }

    @Test func loneHashHasEmptyFragment() {
        let token = SectionTokenParser.activeToken(in: "note #")
        #expect(token?.fragment == "")
    }

    @Test func hashInsideWordIsNotAToken() {
        #expect(SectionTokenParser.activeToken(in: "issue#42") == nil)
    }

    @Test func textWithoutHashHasNoToken() {
        #expect(SectionTokenParser.activeToken(in: "plain note") == nil)
    }
}

@Suite struct TokenMatchTests {
    private let sections = [Section(name: "Research"), Section(name: "Groceries")]

    @Test func prefixMatchIsCaseInsensitive() {
        #expect(SectionTokenParser.matches(fragment: "RE", sections: sections).map(\.name) == ["Research"])
    }

    @Test func emptyFragmentMatchesAllSections() {
        #expect(SectionTokenParser.matches(fragment: "", sections: sections).count == 2)
    }

    @Test func containsMatchRanksAfterPrefixMatch() {
        let sections = [Section(name: "Homework"), Section(name: "Work")]
        #expect(SectionTokenParser.matches(fragment: "work", sections: sections).map(\.name) == ["Work", "Homework"])
    }

    @Test func noMatchReturnsEmpty() {
        #expect(SectionTokenParser.matches(fragment: "zzz", sections: sections).isEmpty)
    }
}

@Suite struct ResolveOnCommitTests {
    @Test func unambiguousPrefixResolvesAndStripsToken() {
        let sections = [Section(name: "Groceries"), Section(name: "Research")]
        let result = SectionTokenParser.resolveOnCommit(text: "buy milk #gro", sections: sections)
        #expect(result?.section.name == "Groceries")
        #expect(result?.cleanedText == "buy milk")
    }

    @Test func ambiguousPrefixResolvesNothing() {
        let sections = [Section(name: "Groceries"), Section(name: "Growth")]
        #expect(SectionTokenParser.resolveOnCommit(text: "buy milk #gro", sections: sections) == nil)
    }

    @Test func exactNameBeatsPrefixAmbiguity() {
        let sections = [Section(name: "Work"), Section(name: "Workout")]
        let result = SectionTokenParser.resolveOnCommit(text: "ship it #work", sections: sections)
        #expect(result?.section.name == "Work")
        #expect(result?.cleanedText == "ship it")
    }

    @Test func unmatchedTokenLeavesTextAlone() {
        let sections = [Section(name: "Research")]
        #expect(SectionTokenParser.resolveOnCommit(text: "note #zzz", sections: sections) == nil)
    }

    @Test func multiWordSectionMatchesByPrefix() {
        let sections = [Section(name: "Deep Work")]
        let result = SectionTokenParser.resolveOnCommit(text: "focus block #deep", sections: sections)
        #expect(result?.section.name == "Deep Work")
        #expect(result?.cleanedText == "focus block")
    }

    @Test func lastTokenDecidesEarlierHashStaysLiteral() {
        let sections = [Section(name: "Research"), Section(name: "Alpha")]
        let result = SectionTokenParser.resolveOnCommit(text: "call #a about #res", sections: sections)
        #expect(result?.section.name == "Research")
        #expect(result?.cleanedText == "call #a about")
    }

    @Test func tokenInMiddleStripsOneAdjacentSpace() {
        let sections = [Section(name: "Groceries")]
        let result = SectionTokenParser.resolveOnCommit(text: "milk #gro tomorrow", sections: sections)
        #expect(result?.cleanedText == "milk tomorrow")
    }

    @Test func tokenAtStartStripsFollowingSpace() {
        let sections = [Section(name: "Groceries")]
        let result = SectionTokenParser.resolveOnCommit(text: "#gro milk", sections: sections)
        #expect(result?.cleanedText == "milk")
    }
}

@Suite struct StripTokenTests {
    @Test func stripRemovesTokenAndPrecedingSpace() {
        guard let token = SectionTokenParser.activeToken(in: "buy milk #gro") else {
            Issue.record("expected token")
            return
        }
        #expect(SectionTokenParser.strip(token, from: "buy milk #gro") == "buy milk")
    }

    @Test func stripKeepsSurroundingWordsSeparated() {
        guard let token = SectionTokenParser.activeToken(in: "a #gro b") else {
            Issue.record("expected token")
            return
        }
        #expect(SectionTokenParser.strip(token, from: "a #gro b") == "a b")
    }
}
