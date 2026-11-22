import UIKit

/// Entry point of the keyboard extension.
///
/// Privacy and security design:
/// - Works fully WITHOUT Full Access. Full Access is optional (`RequestsOpenAccess = YES` only
///   so users can choose it) and is used for exactly one thing: key-press haptics, which iOS
///   doesn't allow otherwise. See `KeyFeedback`.
/// - Contains no networking code at all, so nothing can be sent even with Full Access on.
/// - Never stores, logs or sends keystrokes. No `print`, no files, no UserDefaults, no analytics,
///   no third-party code.
/// - The only text it reads is the context around the cursor, kept in memory for a moment, for
///   auto-capitalization, autocorrect, suggestions, Text Replacement and the double-space period.
/// - Autocorrect uses Apple's on-device spell checker; nothing is learned or saved.
/// - iOS swaps in Apple's own keyboard for password and other secure fields automatically.
final class KeyboardViewController: UIInputViewController {

    private let suggestionBar = SuggestionBar()
    private let keyboardView = KeyboardView()
    private var heightConstraint: NSLayoutConstraint?
    private var barHeightConstraint: NSLayoutConstraint?

    private var mode: KeyboardMode = .letters
    private var shiftState: ShiftState = .off
    private var lastShiftTap: Date?
    private var lastSpaceTap: Date?
    private var deleteTimer: Timer?

    /// The user's own Text Replacement shortcuts (Settings › General › Keyboard › Text Replacement),
    /// keyed by lowercased shortcut. iOS provides these to every keyboard without Full Access;
    /// they are kept in memory only and never stored or sent anywhere.
    private var textReplacements: [String: String] = [:]

    private let autocorrector = Autocorrector()
    private let feedback = KeyFeedback()
    /// The correction space will apply, and the exact word it applies to.
    private var pendingCorrection: (word: String, replacement: String)?

    private var isLandscape: Bool {
        KeyboardMetrics.isLandscape(width: view.bounds.width)
    }

    // MARK: Lifecycle

    override func loadView() {
        // A root view that adopts UIInputViewAudioFeedback, so key clicks can play.
        view = KeyboardInputView(frame: .zero, inputViewStyle: .keyboard)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        suggestionBar.translatesAutoresizingMaskIntoConstraints = false
        suggestionBar.delegate = self
        view.addSubview(suggestionBar)

        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.delegate = self
        keyboardView.inputController = self
        view.addSubview(keyboardView)

        let barHeight = suggestionBar.heightAnchor.constraint(
            equalToConstant: KeyboardMetrics.suggestionBarHeight(landscape: isLandscape)
        )
        barHeightConstraint = barHeight
        NSLayoutConstraint.activate([
            suggestionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionBar.topAnchor.constraint(equalTo: view.topAnchor),
            barHeight,
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: suggestionBar.bottomAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let height = view.heightAnchor.constraint(equalToConstant: KeyboardMetrics.height(landscape: isLandscape))
        height.priority = UILayoutPriority(999)
        height.isActive = true
        heightConstraint = height

        loadLexicon()
        updateAutoShift()
        refresh()
        updateSuggestions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAutoShift()
        refresh()
        updateSuggestions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDeleteRepeat()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let target = KeyboardMetrics.height(landscape: isLandscape)
        if heightConstraint?.constant != target {
            heightConstraint?.constant = target
        }
        let barTarget = KeyboardMetrics.suggestionBarHeight(landscape: isLandscape)
        if barHeightConstraint?.constant != barTarget {
            barHeightConstraint?.constant = barTarget
        }
        // needsInputModeSwitchKey is only reliable once the view is on screen.
        refresh()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refresh()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        updateAutoShift()
        refresh()
        updateSuggestions()
    }

    // MARK: Lexicon (Text Replacement + names that must not be autocorrected)

    private func loadLexicon() {
        requestSupplementaryLexicon { [weak self] lexicon in
            var replacements: [String: String] = [:]
            var known: Set<String> = []
            for entry in lexicon.entries {
                if entry.userInput == entry.documentText {
                    known.insert(entry.documentText.lowercased())   // e.g. contact names
                } else {
                    replacements[entry.userInput.lowercased()] = entry.documentText
                    known.insert(entry.userInput.lowercased())
                }
            }
            DispatchQueue.main.async {
                guard let self else { return }
                self.textReplacements = replacements
                self.autocorrector.knownWords = known
            }
        }
    }

    /// If the word just typed is a Text Replacement shortcut, swap it for its phrase.
    private func applyTextReplacement() -> Bool {
        guard !textReplacements.isEmpty,
              let before = textDocumentProxy.documentContextBeforeInput else { return false }
        let word = String(before.reversed().prefix { !$0.isWhitespace }.reversed())
        guard !word.isEmpty, let replacement = textReplacements[word.lowercased()] else { return false }
        replaceBeforeCursor(characterCount: word.count, with: replacement)
        return true
    }

    // MARK: Autocorrect and suggestions

    private var suggestionsAllowed: Bool {
        let proxy = textDocumentProxy
        if proxy.autocorrectionType == .no { return false }
        switch proxy.keyboardType ?? .default {
        case .URL, .emailAddress, .numberPad, .phonePad, .namePhonePad, .decimalPad, .asciiCapableNumberPad:
            return false
        default:
            return true
        }
    }

    /// The letters (and apostrophes) directly before the cursor.
    private func currentWord() -> String {
        guard let before = textDocumentProxy.documentContextBeforeInput else { return "" }
        return String(before.reversed().prefix { $0.isLetter || $0 == "'" || $0 == "’" }.reversed())
    }

    private func updateSuggestions() {
        pendingCorrection = nil
        let word = currentWord()
        // Mid-word cursor (e.g. after the trackpad) or suggestions disabled: show an empty bar.
        let cursorMidWord = textDocumentProxy.documentContextAfterInput?.first?.isLetter == true
        guard suggestionsAllowed, !word.isEmpty, !cursorMidWord else {
            suggestionBar.show([])
            return
        }

        let result = autocorrector.analyze(word)
        if let correction = result.correction {
            pendingCorrection = (word, correction)
        }
        suggestionBar.show(result.suggestions)
    }

    /// Runs when a word is completed by space, return or punctuation:
    /// Text Replacement first, otherwise the pending autocorrection.
    private func finishWord() {
        if applyTextReplacement() { return }
        guard let pending = pendingCorrection, currentWord() == pending.word else { return }
        replaceBeforeCursor(characterCount: pending.word.count, with: pending.replacement)
    }

    private func replaceBeforeCursor(characterCount: Int, with text: String) {
        for _ in 0..<characterCount {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(text)
    }

    // MARK: State

    private func refresh() {
        let proxy = textDocumentProxy
        let returnType = proxy.returnKeyType ?? .default

        var state = KeyboardState()
        state.mode = mode
        state.shift = shiftState
        state.showsGlobe = needsInputModeSwitchKey
        state.returnTitle = Self.returnTitle(for: returnType)
        state.returnIsProminent = returnType != .default
        state.returnEnabled = !(proxy.enablesReturnKeyAutomatically ?? false) || proxy.hasText

        switch proxy.keyboardAppearance ?? .default {
        case .dark: state.theme = .dark
        case .light: state.theme = .light
        default: state.theme = .system
        }

        keyboardView.apply(state)
        suggestionBar.apply(theme: state.theme)
    }

    private func updateAutoShift() {
        guard shiftState != .capsLock else { return }
        shiftState = shouldAutoCapitalize() ? .on : .off
    }

    private func shouldAutoCapitalize() -> Bool {
        let proxy = textDocumentProxy
        let before = proxy.documentContextBeforeInput ?? ""

        switch proxy.autocapitalizationType ?? .sentences {
        case .none:
            return false
        case .allCharacters:
            return true
        case .words:
            guard let last = before.last else { return true }
            return last.isWhitespace
        case .sentences:
            guard let lastNonSpace = before.last(where: { !$0.isWhitespace }) else { return true }
            guard let last = before.last, last.isWhitespace else { return false }
            if last.isNewline { return true }
            return lastNonSpace == "." || lastNonSpace == "!" || lastNonSpace == "?"
        @unknown default:
            return false
        }
    }

    /// Punctuation that completes a word and so triggers Text Replacement and autocorrect.
    private static let wordEndingPunctuation: Set<String> = [".", ",", "!", "?", ";", ":"]

    private static func returnTitle(for type: UIReturnKeyType) -> String {
        switch type {
        case .go: return "go"
        case .google, .yahoo, .search: return "search"
        case .join: return "join"
        case .next: return "next"
        case .route: return "route"
        case .send: return "send"
        case .done: return "done"
        case .emergencyCall: return "Emergency"
        case .continue: return "continue"
        default: return "return"
        }
    }

    // MARK: Key actions

    private func handleShiftTap() {
        let now = Date()
        if let last = lastShiftTap, now.timeIntervalSince(last) < 0.35 {
            shiftState = .capsLock
            lastShiftTap = nil
        } else {
            shiftState = shiftState == .off ? .on : .off
            lastShiftTap = now
        }
    }

    /// Double-tapping space after a word types ". " like the system keyboard.
    private func insertPeriodShortcut() -> Bool {
        let proxy = textDocumentProxy
        guard let before = proxy.documentContextBeforeInput, before.hasSuffix(" ") else { return false }
        guard let previous = before.dropLast().last,
              previous.isLetter || previous.isNumber || previous == "'" || previous == "’" else { return false }
        proxy.deleteBackward()
        proxy.insertText(". ")
        return true
    }

    private func performDelete() {
        textDocumentProxy.deleteBackward()
        updateAutoShift()
        refresh()
        updateSuggestions()
    }

    @objc private func startDeleteRepeating() {
        let timer = Timer(timeInterval: 0.08, target: self, selector: #selector(repeatDelete), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        deleteTimer = timer
    }

    @objc private func repeatDelete() {
        performDelete()
    }

    private func stopDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
}

extension KeyboardViewController: KeyboardViewDelegate {
    func keyboardView(_ keyboardView: KeyboardView, didTap kind: KeyKind) {
        let proxy = textDocumentProxy
        let previousSpaceTap = lastSpaceTap
        lastSpaceTap = nil
        if kind != .shift {
            lastShiftTap = nil
        }

        switch kind {
        case .character(let value):
            if Self.wordEndingPunctuation.contains(value) {
                finishWord()
            }
            let text = (mode == .letters && shiftState != .off) ? value.uppercased() : value
            proxy.insertText(text)
            updateAutoShift()

        case .space:
            let isDoubleTap = previousSpaceTap.map { Date().timeIntervalSince($0) < 0.6 } ?? false
            if !(isDoubleTap && insertPeriodShortcut()) {
                finishWord()
                proxy.insertText(" ")
                lastSpaceTap = Date()
            }
            mode = .letters
            updateAutoShift()

        case .returnKey:
            finishWord()
            proxy.insertText("\n")
            updateAutoShift()

        case .shift:
            handleShiftTap()

        case .modeChange(let newMode):
            mode = newMode
            updateAutoShift()

        case .delete, .nextKeyboard:
            break // Handled by dedicated touch handlers.
        }

        refresh()
        updateSuggestions()
    }

    func keyboardViewDidBeginDelete(_ keyboardView: KeyboardView) {
        lastSpaceTap = nil
        stopDeleteRepeat()
        performDelete()
        let delay = Timer(timeInterval: 0.45, target: self, selector: #selector(startDeleteRepeating), userInfo: nil, repeats: false)
        RunLoop.main.add(delay, forMode: .common)
        deleteTimer = delay
    }

    func keyboardViewDidEndDelete(_ keyboardView: KeyboardView) {
        stopDeleteRepeat()
    }

    func keyboardViewDidPressKey(_ keyboardView: KeyboardView) {
        feedback.keyPressed(hasFullAccess: hasFullAccess)
    }

    func keyboardView(_ keyboardView: KeyboardView, moveCursorBy offset: Int) {
        lastSpaceTap = nil
        textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
        updateSuggestions()
    }
}

extension KeyboardViewController: SuggestionBarDelegate {
    func suggestionBar(_ bar: SuggestionBar, didSelect suggestion: Suggestion) {
        feedback.keyPressed(hasFullAccess: hasFullAccess)
        let word = currentWord()
        if suggestion.kind == .verbatim {
            // "Keep what I typed": don't correct this word again while the keyboard is open.
            autocorrector.keep(word)
        } else if !word.isEmpty {
            replaceBeforeCursor(characterCount: word.count, with: suggestion.text)
        } else {
            textDocumentProxy.insertText(suggestion.text)
        }
        textDocumentProxy.insertText(" ")
        lastSpaceTap = nil
        mode = .letters
        updateAutoShift()
        refresh()
        updateSuggestions()
    }
}
