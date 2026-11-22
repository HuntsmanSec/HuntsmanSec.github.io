import UIKit

struct KeyPalette {
    let keyBackground: UIColor
    let specialBackground: UIColor
    let text: UIColor
    let shadow: UIColor
    let keyboardBackground: UIColor

    static let light = KeyPalette(
        keyBackground: .white,
        specialBackground: UIColor(red: 0.67, green: 0.70, blue: 0.74, alpha: 1),
        text: .black,
        shadow: UIColor(red: 0.53, green: 0.54, blue: 0.56, alpha: 1),
        keyboardBackground: UIColor(red: 0.82, green: 0.83, blue: 0.86, alpha: 1)
    )

    static let dark = KeyPalette(
        keyBackground: UIColor(white: 0.42, alpha: 1),
        specialBackground: UIColor(white: 0.27, alpha: 1),
        text: .white,
        shadow: .black,
        keyboardBackground: UIColor(white: 0.11, alpha: 1)
    )

    /// Adaptive colors that switch instantly when the phone toggles Dark Mode.
    static let system = KeyPalette(
        keyBackground: adaptive(light.keyBackground, dark.keyBackground),
        specialBackground: adaptive(light.specialBackground, dark.specialBackground),
        text: adaptive(light.text, dark.text),
        shadow: adaptive(light.shadow, dark.shadow),
        keyboardBackground: adaptive(light.keyboardBackground, dark.keyboardBackground)
    )

    static func forTheme(_ theme: KeyboardTheme) -> KeyPalette {
        switch theme {
        case .system: return .system
        case .light: return .light
        case .dark: return .dark
        }
    }

    private static func adaptive(_ lightColor: UIColor, _ darkColor: UIColor) -> UIColor {
        UIColor { traits in traits.userInterfaceStyle == .dark ? darkColor : lightColor }
    }
}

/// A single key. Draws itself from `KeyboardState`; it holds no text the user typed.
final class KeyButton: UIControl {
    enum Style {
        case regular
        case special
        case prominent
    }

    let key: Key

    /// Extra touch area around the visible key, so taps in the gaps between keys still count.
    var hitOutset: UIEdgeInsets = .zero

    private let background = UIView()
    private let label = UILabel()
    private let icon = UIImageView()
    private var palette = KeyPalette.light
    private var style: Style = .regular

    init(key: Key) {
        self.key = key
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityTraits = .keyboardKey

        background.isUserInteractionEnabled = false
        background.layer.cornerRadius = 5
        background.layer.cornerCurve = .continuous
        background.layer.shadowOffset = CGSize(width: 0, height: 1)
        background.layer.shadowRadius = 0
        background.layer.shadowOpacity = 0.35
        addSubview(background)

        label.isUserInteractionEnabled = false
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        addSubview(label)

        icon.isUserInteractionEnabled = false
        icon.contentMode = .center
        addSubview(icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        background.frame = bounds
        label.frame = bounds.insetBy(dx: 2, dy: 0)
        icon.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet { updateColors() }
    }

    override var isEnabled: Bool {
        didSet { updateColors() }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expanded = bounds.inset(by: UIEdgeInsets(
            top: -hitOutset.top,
            left: -hitOutset.left,
            bottom: -hitOutset.bottom,
            right: -hitOutset.right
        ))
        return expanded.contains(point)
    }

    func apply(_ state: KeyboardState) {
        palette = KeyPalette.forTheme(state.theme)
        accessibilityValue = nil

        switch key.kind {
        case .character(let value):
            let shown = (state.mode == .letters && state.shift != .off) ? value.uppercased() : value
            show(text: shown, size: key.isCompact ? 20 : 24)
            accessibilityLabel = shown
            style = .regular

        case .space:
            show(text: "space", size: 16)
            accessibilityLabel = "Space"
            style = .regular

        case .shift:
            let symbol: String
            switch state.shift {
            case .off: symbol = "shift"
            case .on: symbol = "shift.fill"
            case .capsLock: symbol = "capslock.fill"
            }
            show(symbol: symbol)
            accessibilityLabel = "Shift"
            switch state.shift {
            case .off: accessibilityValue = "Off"
            case .on: accessibilityValue = "On"
            case .capsLock: accessibilityValue = "Caps lock"
            }
            style = state.shift == .off ? .special : .regular

        case .delete:
            show(symbol: "delete.left")
            accessibilityLabel = "Delete"
            style = .special

        case .nextKeyboard:
            show(symbol: "globe")
            accessibilityLabel = "Next keyboard"
            style = .special

        case .modeChange(let target):
            switch target {
            case .letters:
                show(text: "ABC", size: 16)
                accessibilityLabel = "Letters"
            case .numbers:
                show(text: "123", size: 16)
                accessibilityLabel = "Numbers"
            case .symbols:
                show(text: "#+=", size: 16)
                accessibilityLabel = "More symbols"
            }
            style = .special

        case .returnKey:
            show(text: state.returnTitle, size: 16)
            accessibilityLabel = state.returnTitle
            style = state.returnIsProminent ? .prominent : .special
            isEnabled = state.returnEnabled
        }

        updateColors()
    }

    /// Hides the key's letter/icon while the space bar is used as a trackpad, like the system keyboard.
    func setLegendHidden(_ hidden: Bool) {
        label.alpha = hidden ? 0 : 1
        icon.alpha = hidden ? 0 : 1
    }

    private func show(text: String, size: CGFloat) {
        label.text = text
        label.font = .systemFont(ofSize: size)
        label.isHidden = false
        icon.isHidden = true
    }

    private func show(symbol name: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        icon.image = UIImage(systemName: name, withConfiguration: config)
        icon.isHidden = false
        label.isHidden = true
    }

    private func updateColors() {
        let effectiveStyle: Style = (style == .prominent && !isEnabled) ? .special : style
        let fill: UIColor
        let foreground: UIColor

        switch effectiveStyle {
        case .regular:
            fill = isHighlighted ? palette.specialBackground : palette.keyBackground
            foreground = palette.text
        case .special:
            fill = isHighlighted ? palette.keyBackground : palette.specialBackground
            foreground = palette.text
        case .prominent:
            fill = isHighlighted ? palette.specialBackground : .systemBlue
            foreground = .white
        }

        background.backgroundColor = fill
        // CGColor doesn't adapt by itself, so resolve it for the current light/dark style.
        background.layer.shadowColor = palette.shadow.resolvedColor(with: traitCollection).cgColor
        let color = isEnabled ? foreground : foreground.withAlphaComponent(0.35)
        label.textColor = color
        icon.tintColor = color
    }
}
