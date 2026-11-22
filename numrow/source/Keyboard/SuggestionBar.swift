import UIKit

struct Suggestion: Equatable {
    enum Kind {
        /// Keep exactly what was typed (shown in quotes when a correction is pending).
        case verbatim
        /// The autocorrection that space will apply (shown bold and highlighted).
        case correction
        /// A word completion or alternative spelling.
        case completion
    }

    let title: String
    let text: String
    let kind: Kind
}

protocol SuggestionBarDelegate: AnyObject {
    func suggestionBar(_ bar: SuggestionBar, didSelect suggestion: Suggestion)
}

/// The three-slot word suggestion strip above the keys, like the system keyboard's.
final class SuggestionBar: UIView {
    weak var delegate: SuggestionBarDelegate?

    private let slots: [UIButton] = (0..<3).map { _ in UIButton(type: .custom) }
    private let dividers: [UIView] = (0..<2).map { _ in UIView() }
    private var slotItems: [Suggestion?] = [nil, nil, nil]
    private var palette = KeyPalette.system

    override init(frame: CGRect) {
        super.init(frame: frame)
        for (index, button) in slots.enumerated() {
            button.tag = index
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.6
            button.titleLabel?.lineBreakMode = .byTruncatingMiddle
            button.layer.cornerRadius = 6
            button.layer.cornerCurve = .continuous
            button.accessibilityTraits = .keyboardKey
            button.addTarget(self, action: #selector(slotTapped(_:)), for: .touchUpInside)
            addSubview(button)
        }
        dividers.forEach(addSubview)
        applyColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func apply(theme: KeyboardTheme) {
        palette = KeyPalette.forTheme(theme)
        applyColors()
    }

    /// Shows up to three suggestions. A correction is placed in the middle slot, like iOS.
    func show(_ items: [Suggestion]) {
        var arranged: [Suggestion?] = [nil, nil, nil]
        switch items.count {
        case 0: break
        case 1: arranged[1] = items[0]
        default:
            for (index, item) in items.prefix(3).enumerated() {
                arranged[index] = item
            }
        }
        guard arranged != slotItems else { return }
        slotItems = arranged

        for (index, button) in slots.enumerated() {
            let item = arranged[index]
            button.setTitle(item?.title, for: .normal)
            button.titleLabel?.font = item?.kind == .correction
                ? .systemFont(ofSize: 17, weight: .semibold)
                : .systemFont(ofSize: 17)
            button.isEnabled = item != nil
            button.isAccessibilityElement = item != nil
            button.accessibilityLabel = item.map { suggestion in
                switch suggestion.kind {
                case .verbatim: return "Keep \(suggestion.text)"
                case .correction: return "Correct to \(suggestion.text)"
                case .completion: return suggestion.text
                }
            }
        }
        applyColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width / 3
        for (index, button) in slots.enumerated() {
            button.frame = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: bounds.height)
                .insetBy(dx: 4, dy: 4)
        }
        let dividerHeight = bounds.height * 0.5
        for (index, divider) in dividers.enumerated() {
            divider.frame = CGRect(
                x: CGFloat(index + 1) * width - 0.5,
                y: (bounds.height - dividerHeight) / 2,
                width: 1,
                height: dividerHeight
            )
        }
    }

    @objc private func slotTapped(_ sender: UIButton) {
        guard let item = slotItems[sender.tag] else { return }
        delegate?.suggestionBar(self, didSelect: item)
    }

    private func applyColors() {
        backgroundColor = palette.keyboardBackground
        for (index, button) in slots.enumerated() {
            button.setTitleColor(palette.text, for: .normal)
            button.setTitleColor(palette.text.withAlphaComponent(0.4), for: .highlighted)
            button.backgroundColor = slotItems[index]?.kind == .correction ? palette.keyBackground : .clear
        }
        dividers.forEach { $0.backgroundColor = palette.text.withAlphaComponent(0.2) }
    }
}
