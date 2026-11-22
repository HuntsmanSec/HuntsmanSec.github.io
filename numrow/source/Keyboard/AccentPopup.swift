import UIKit

/// The bubble of accented characters shown when a letter key is held down.
/// The finger slides across it to pick a character; releasing inserts the highlighted one.
final class AccentPopup: UIView {
    let variants: [String]
    private(set) var selectedIndex = 0

    private let labels: [UILabel]
    private let palette: KeyPalette

    init(variants: [String], displayed: [String], palette: KeyPalette) {
        self.variants = variants
        self.palette = palette
        self.labels = displayed.map { text in
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 24)
            label.textAlignment = .center
            label.layer.cornerRadius = 6
            label.layer.cornerCurve = .continuous
            label.clipsToBounds = true
            return label
        }
        super.init(frame: .zero)

        isUserInteractionEnabled = false
        backgroundColor = palette.keyBackground
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
        labels.forEach(addSubview)

        isAccessibilityElement = false
        updateSelection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cellWidth = bounds.width / CGFloat(max(labels.count, 1))
        for (index, label) in labels.enumerated() {
            label.frame = CGRect(x: CGFloat(index) * cellWidth, y: 0, width: cellWidth, height: bounds.height)
                .insetBy(dx: 2, dy: 4)
        }
        layer.shadowColor = palette.shadow.resolvedColor(with: traitCollection).cgColor
    }

    /// Selects the cell under an x position in this view's coordinates (clamped to the ends).
    func select(atX x: CGFloat) {
        guard !labels.isEmpty, bounds.width > 0 else { return }
        let cellWidth = bounds.width / CGFloat(labels.count)
        let index = min(max(Int(x / cellWidth), 0), labels.count - 1)
        if index != selectedIndex {
            selectedIndex = index
            updateSelection()
        }
    }

    private func updateSelection() {
        for (index, label) in labels.enumerated() {
            let selected = index == selectedIndex
            label.backgroundColor = selected ? .systemBlue : .clear
            label.textColor = selected ? .white : palette.text
        }
    }
}
