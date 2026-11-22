import UIKit

/// Which character set the keyboard is showing.
enum KeyboardMode: Equatable {
    case letters
    case numbers
    case symbols
}

enum ShiftState: Equatable {
    case off
    case on
    case capsLock
}

/// What a key does when pressed.
enum KeyKind: Equatable {
    case character(String)
    case shift
    case delete
    case space
    case returnKey
    case nextKeyboard
    case modeChange(KeyboardMode)
}

struct Key {
    let kind: KeyKind
    /// Width relative to a standard letter key. Every row adds up to at most `KeyboardLayout.rowUnits`.
    let widthUnits: CGFloat
    /// Number-row keys are shorter with smaller digits, to keep the keyboard compact.
    let isCompact: Bool

    init(_ kind: KeyKind, _ widthUnits: CGFloat = 1, isCompact: Bool = false) {
        self.kind = kind
        self.widthUnits = widthUnits
        self.isCompact = isCompact
    }
}

/// Light/dark styling. `.system` follows the phone's Dark Mode setting automatically;
/// `.light`/`.dark` are used when the app being typed into forces a keyboard appearance.
enum KeyboardTheme: Equatable {
    case system
    case light
    case dark
}

/// Everything the key views need to draw themselves.
struct KeyboardState: Equatable {
    var mode: KeyboardMode = .letters
    var shift: ShiftState = .off
    var showsGlobe = true
    var returnTitle = "return"
    var returnIsProminent = false
    var returnEnabled = true
    var theme: KeyboardTheme = .system
}

enum KeyboardMetrics {
    /// Total keyboard height: suggestion bar + compact number row + four standard rows.
    /// Layout is proportional, so the same values fit every iPhone width from SE to Pro Max.
    static func height(landscape: Bool) -> CGFloat {
        landscape ? 220 : 300
    }

    static func suggestionBarHeight(landscape: Bool) -> CGFloat {
        landscape ? 30 : 40
    }

    /// Keyboard extensions don't reliably get a landscape size class, so use the width:
    /// every iPhone is under 500pt wide in portrait and wider than that in landscape.
    static func isLandscape(width: CGFloat) -> Bool {
        width > 500
    }

    /// The number row's height relative to a letter row.
    static let numberRowScale: CGFloat = 0.75
}

enum KeyboardLayout {
    /// Width of a full row, measured in letter-key units.
    static let rowUnits: CGFloat = 10

    /// Characters shown in the long-press bubble, matching the standard English (US) keyboard.
    static let accentVariants: [String: [String]] = [
        "a": ["à", "á", "â", "ä", "æ", "ã", "å", "ā"],
        "c": ["ç", "ć", "č"],
        "e": ["è", "é", "ê", "ë", "ē", "ė", "ę"],
        "i": ["î", "ï", "í", "ī", "į", "ì"],
        "l": ["ł"],
        "n": ["ñ", "ń"],
        "o": ["ô", "ö", "ò", "ó", "œ", "ø", "ō", "õ"],
        "s": ["ß", "ś", "š"],
        "u": ["û", "ü", "ù", "ú", "ū"],
        "y": ["ÿ"],
        "z": ["ž", "ź", "ż"],
    ]

    static func rows(mode: KeyboardMode, showsGlobe: Bool) -> [[Key]] {
        // The number row is always on top, in every mode. This is the point of the keyboard.
        var rows: [[Key]] = [characters("1234567890", compact: true)]

        switch mode {
        case .letters:
            rows.append(characters("qwertyuiop"))
            rows.append(characters("asdfghjkl"))
            rows.append([Key(.shift, 1.5)] + characters("zxcvbnm") + [Key(.delete, 1.5)])
        case .numbers:
            rows.append(characters("-/:;()$&@\""))
            rows.append(characters("[]{}#%^*+="))
            rows.append([Key(.modeChange(.symbols), 1.5)] + characters(".,?!'", width: 1.4) + [Key(.delete, 1.5)])
        case .symbols:
            rows.append(characters("_\\|~<>€£¥•"))
            rows.append(characters("`°…¿¡§¶©®™"))
            rows.append([Key(.modeChange(.numbers), 1.5)] + characters(".,?!'", width: 1.4) + [Key(.delete, 1.5)])
        }

        let modeKey = Key(.modeChange(mode == .letters ? .numbers : .letters), 1.25)
        var bottom: [Key] = [modeKey]
        if showsGlobe {
            bottom.append(Key(.nextKeyboard, 1.25))
        }
        bottom.append(Key(.space, showsGlobe ? 5 : 6.25))
        bottom.append(Key(.returnKey, 2.5))
        rows.append(bottom)

        return rows
    }

    private static func characters(_ string: String, width: CGFloat = 1, compact: Bool = false) -> [Key] {
        string.map { Key(.character(String($0)), width, isCompact: compact) }
    }
}
