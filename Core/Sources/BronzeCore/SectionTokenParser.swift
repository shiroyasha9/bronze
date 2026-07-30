import Foundation

public enum SectionTokenParser {
    public struct Token: Equatable {
        public let range: Range<String.Index>
        public let fragment: String
    }

    public static func activeToken(in text: String) -> Token? {
        var found: Token?
        var index = text.startIndex
        while index < text.endIndex, let hash = text[index...].firstIndex(of: "#") {
            let atBoundary = hash == text.startIndex || text[text.index(before: hash)].isWhitespace
            if atBoundary {
                let fragmentStart = text.index(after: hash)
                let fragmentEnd = text[fragmentStart...].firstIndex(where: \.isWhitespace) ?? text.endIndex
                found = Token(range: hash..<fragmentEnd, fragment: String(text[fragmentStart..<fragmentEnd]))
            }
            index = text.index(after: hash)
        }
        return found
    }

    public static func matches(fragment: String, sections: [Section]) -> [Section] {
        let needle = fragment.lowercased()
        guard !needle.isEmpty else { return sections }
        let prefixed = sections.filter { $0.name.lowercased().hasPrefix(needle) }
        let contained = sections.filter {
            let name = $0.name.lowercased()
            return !name.hasPrefix(needle) && name.contains(needle)
        }
        return prefixed + contained
    }

    public static func resolveOnCommit(
        text: String,
        sections: [Section]
    ) -> (section: Section, cleanedText: String)? {
        guard let token = activeToken(in: text), !token.fragment.isEmpty else { return nil }
        let needle = token.fragment.lowercased()
        let exact = sections.filter { $0.name.lowercased() == needle }
        let prefixed = sections.filter { $0.name.lowercased().hasPrefix(needle) }
        let candidates = exact.count == 1 ? exact : prefixed
        guard candidates.count == 1 else { return nil }
        return (candidates[0], strip(token, from: text))
    }

    public static func strip(_ token: Token, from text: String) -> String {
        var removal = token.range
        if removal.lowerBound > text.startIndex,
           text[text.index(before: removal.lowerBound)].isWhitespace {
            removal = text.index(before: removal.lowerBound)..<removal.upperBound
        } else if removal.upperBound < text.endIndex,
                  text[removal.upperBound].isWhitespace {
            removal = removal.lowerBound..<text.index(after: removal.upperBound)
        }
        var result = text
        result.removeSubrange(removal)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
