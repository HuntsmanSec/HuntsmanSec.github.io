import UIKit

/// On-device spelling correction and word completion built on Apple's `UITextChecker`.
///
/// Privacy: everything runs locally on the iPhone. Nothing is learned, saved to disk or sent
/// anywhere; words the user chooses to keep are remembered in memory only until the keyboard closes.
final class Autocorrector {
    struct Result {
        /// What space will change the word into, if anything.
        let correction: String?
        /// Up to three suggestions for the bar, in display order.
        let suggestions: [Suggestion]
    }

    private let checker = UITextChecker()
    private let language: String

    /// Words that must never be "corrected": contact names and Text Replacement phrases from iOS.
    var knownWords: Set<String> = []
    /// Words the user kept by tapping the quoted suggestion (in memory only).
    private var keptWords: Set<String> = []

    /// Missing apostrophes and the lone "i", which the system keyboard fixes too.
    private static let commonFixes: [String: String] = [
        "i": "I", "im": "I'm", "ive": "I've", "dont": "don't", "cant": "can't", "didnt": "didn't",
        "doesnt": "doesn't", "isnt": "isn't", "wasnt": "wasn't", "arent": "aren't", "werent": "weren't",
        "couldnt": "couldn't", "shouldnt": "shouldn't", "wouldnt": "wouldn't", "havent": "haven't",
        "hasnt": "hasn't", "thats": "that's", "whats": "what's", "theyre": "they're", "youre": "you're",
        "shes": "she's", "theres": "there's", "youve": "you've", "theyve": "they've", "weve": "we've",
    ]

    init() {
        let preferred = ["en_US", "en"]
        language = preferred.first { UITextChecker.availableLanguages.contains($0) } ?? "en_US"
    }

    func keep(_ word: String) {
        keptWords.insert(word.lowercased())
    }

    func analyze(_ word: String) -> Result {
        guard !word.isEmpty else { return Result(correction: nil, suggestions: []) }

        let range = NSRange(location: 0, length: (word as NSString).length)
        let correction = self.correction(for: word, range: range)

        var alternatives: [String] = []
        if correction != nil {
            alternatives += (checker.guesses(forWordRange: range, in: word, language: language) ?? []).dropFirst()
        }
        alternatives += checker.completions(forPartialWordRange: range, in: word, language: language) ?? []
        let lowered = Set([word.lowercased(), correction?.lowercased()].compactMap { $0 })
        var seen = lowered
        let extras = alternatives
            .map { Self.matchCase($0, to: word) }
            .filter { seen.insert($0.lowercased()).inserted }

        var suggestions: [Suggestion] = []
        if let correction {
            suggestions.append(Suggestion(title: "“\(word)”", text: word, kind: .verbatim))
            suggestions.append(Suggestion(title: correction, text: correction, kind: .correction))
            if let extra = extras.first {
                suggestions.append(Suggestion(title: extra, text: extra, kind: .completion))
            }
        } else {
            suggestions.append(Suggestion(title: word, text: word, kind: .verbatim))
            for extra in extras.prefix(2) {
                suggestions.append(Suggestion(title: extra, text: extra, kind: .completion))
            }
            // Put the typed word in the left slot and completions after it, like iOS.
            if suggestions.count == 1 { suggestions = [] }
        }
        return Result(correction: correction, suggestions: suggestions)
    }

    private func correction(for word: String, range: NSRange) -> String? {
        let lower = word.lowercased()
        guard !keptWords.contains(lower), !knownWords.contains(lower) else { return nil }

        if let fix = Self.commonFixes[lower] {
            return lower == "i" ? fix : Self.matchCase(fix, to: word)
        }
        // Leave short words and ALL-CAPS acronyms alone.
        guard word.count >= 3, word != word.uppercased() else { return nil }

        let misspelled = checker.rangeOfMisspelledWord(
            in: word, range: range, startingAt: 0, wrap: false, language: language
        )
        guard misspelled.location != NSNotFound,
              let guess = checker.guesses(forWordRange: range, in: word, language: language)?.first
        else { return nil }
        return Self.matchCase(guess, to: word)
    }

    /// Keeps a capitalized word capitalized after correction.
    private static func matchCase(_ candidate: String, to typed: String) -> String {
        guard let first = typed.first, first.isUppercase, let candidateFirst = candidate.first else {
            return candidate
        }
        return candidateFirst.uppercased() + candidate.dropFirst()
    }
}
