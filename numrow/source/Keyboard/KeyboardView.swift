import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ keyboardView: KeyboardView, didTap kind: KeyKind)
    func keyboardViewDidBeginDelete(_ keyboardView: KeyboardView)
    func keyboardViewDidEndDelete(_ keyboardView: KeyboardView)
    /// Space-bar trackpad: move the cursor left (negative) or right (positive) by characters.
    func keyboardView(_ keyboardView: KeyboardView, moveCursorBy offset: Int)
    /// A finger just went down on a key, or a long-press popup opened (for sound and haptics).
    func keyboardViewDidPressKey(_ keyboardView: KeyboardView)
}

/// Lays out the keys proportionally so one layout fits every iPhone size and orientation.
final class KeyboardView: UIView {
    weak var delegate: KeyboardViewDelegate?
    /// Needed so the globe key can show the system's keyboard switcher.
    weak var inputController: UIInputViewController?

    private var rows: [[KeyButton]] = []
    private var state = KeyboardState()

    // Long-press features: accent bubble on letters, trackpad on the space bar.
    private enum PressMode {
        case none
        case accents
        case trackpad
    }
    private var pressMode: PressMode = .none
    private var accentPopup: AccentPopup?
    private var trackpadAnchorX: CGFloat = 0
    /// Points of horizontal finger travel per one-character cursor move.
    private let trackpadStep: CGFloat = 9

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.4
        longPress.allowableMovement = 20
        // Cancels the key's own tap so a long-press never also types the plain letter or a space.
        longPress.cancelsTouchesInView = true
        longPress.delegate = self
        addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func apply(_ newState: KeyboardState) {
        let needsRebuild = rows.isEmpty
            || newState.mode != state.mode
            || newState.showsGlobe != state.showsGlobe
        state = newState
        backgroundColor = KeyPalette.forTheme(state.theme).keyboardBackground

        if needsRebuild {
            rebuild()
        }
        for row in rows {
            for button in row {
                button.apply(state)
            }
        }
    }

    private func rebuild() {
        // Old keys are going away; make sure a held delete key can't keep repeating.
        delegate?.keyboardViewDidEndDelete(self)
        finishLongPress()

        for button in rows.joined() {
            button.removeFromSuperview()
        }
        rows = KeyboardLayout.rows(mode: state.mode, showsGlobe: state.showsGlobe).map { row in
            row.map { key in
                let button = KeyButton(key: key)
                wire(button)
                addSubview(button)
                return button
            }
        }
        setNeedsLayout()
    }

    private func wire(_ button: KeyButton) {
        // Click/haptic on touch-down, like the system keyboard, so it feels instant.
        button.addTarget(self, action: #selector(keyDown), for: .touchDown)

        switch button.key.kind {
        case .nextKeyboard:
            if let controller = inputController {
                button.addTarget(
                    controller,
                    action: #selector(UIInputViewController.handleInputModeList(from:with:)),
                    for: .allTouchEvents
                )
            }
        case .delete:
            button.addTarget(self, action: #selector(deleteDown), for: .touchDown)
            button.addTarget(self, action: #selector(deleteUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        default:
            button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        }
    }

    @objc private func keyTapped(_ sender: KeyButton) {
        delegate?.keyboardView(self, didTap: sender.key.kind)
    }

    @objc private func keyDown() {
        delegate?.keyboardViewDidPressKey(self)
    }

    @objc private func deleteDown() {
        delegate?.keyboardViewDidBeginDelete(self)
    }

    @objc private func deleteUp() {
        delegate?.keyboardViewDidEndDelete(self)
    }

    // MARK: Long press (accents and trackpad)

    private func button(at point: CGPoint) -> KeyButton? {
        rows.joined().first { $0.point(inside: $0.convert(point, from: self), with: nil) }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: self)

        switch gesture.state {
        case .began:
            guard let button = button(at: point) else { return }
            switch button.key.kind {
            case .space:
                beginTrackpad(at: point)
            case .character(let value):
                if let variants = KeyboardLayout.accentVariants[value] {
                    showAccents(variants, over: button, at: point)
                }
            default:
                break
            }

        case .changed:
            switch pressMode {
            case .trackpad:
                moveTrackpad(to: point)
            case .accents:
                if let popup = accentPopup {
                    popup.select(atX: popup.convert(point, from: self).x)
                }
            case .none:
                break
            }

        case .ended:
            if pressMode == .accents, let popup = accentPopup {
                let chosen = popup.variants[popup.selectedIndex]
                finishLongPress()
                delegate?.keyboardView(self, didTap: .character(chosen))
            } else {
                finishLongPress()
            }

        case .cancelled, .failed:
            finishLongPress()

        default:
            break
        }
    }

    private func showAccents(_ variants: [String], over button: KeyButton, at point: CGPoint) {
        let uppercase = state.mode == .letters && state.shift != .off
        let displayed = variants.map { uppercase ? $0.uppercased() : $0 }
        let palette = KeyPalette.forTheme(state.theme)
        let popup = AccentPopup(variants: variants, displayed: displayed, palette: palette)

        // The bubble must stay inside the keyboard: iOS clips anything drawn outside it.
        let cellWidth = max(button.bounds.width, 30)
        let width = min(cellWidth * CGFloat(variants.count), bounds.width - 4)
        let height = button.bounds.height + 8
        let x = min(max(2, button.frame.midX - cellWidth / 2), bounds.width - width - 2)
        let y = max(0, button.frame.minY - height - 4)
        popup.frame = CGRect(x: x, y: y, width: width, height: height)

        addSubview(popup)
        popup.layoutIfNeeded()
        popup.select(atX: popup.convert(point, from: self).x)
        accentPopup = popup
        pressMode = .accents
        delegate?.keyboardViewDidPressKey(self)
    }

    private func beginTrackpad(at point: CGPoint) {
        pressMode = .trackpad
        delegate?.keyboardViewDidPressKey(self)
        trackpadAnchorX = point.x
        rows.joined().forEach { $0.setLegendHidden(true) }
    }

    private func moveTrackpad(to point: CGPoint) {
        let steps = Int((point.x - trackpadAnchorX) / trackpadStep)
        guard steps != 0 else { return }
        trackpadAnchorX += CGFloat(steps) * trackpadStep
        delegate?.keyboardView(self, moveCursorBy: steps)
    }

    private func finishLongPress() {
        accentPopup?.removeFromSuperview()
        accentPopup = nil
        if pressMode == .trackpad {
            rows.joined().forEach { $0.setLegendHidden(false) }
        }
        pressMode = .none
    }

    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !rows.isEmpty, bounds.width > 0, bounds.height > 0 else { return }

        let compact = KeyboardMetrics.isLandscape(width: bounds.width)
        let top: CGFloat = compact ? 2 : 4
        let bottom: CGFloat = compact ? 2 : 4
        let side: CGFloat = 3
        let rowGap: CGFloat = compact ? 5 : 10
        let keyGap: CGFloat = 6

        // The number row (first row) is shorter than the letter rows.
        let weights = rows.indices.map { $0 == 0 ? KeyboardMetrics.numberRowScale : 1 }
        let totalWeight = weights.reduce(0, +)
        let available = bounds.height - top - bottom - rowGap * CGFloat(rows.count - 1)
        let unitHeight = max(0, available / totalWeight)
        let unit = (bounds.width - side * 2) / KeyboardLayout.rowUnits

        var y = top
        for (rowIndex, row) in rows.enumerated() {
            let rowHeight = unitHeight * weights[rowIndex]
            let usedUnits = row.reduce(CGFloat(0)) { $0 + $1.key.widthUnits }
            var x = side + (KeyboardLayout.rowUnits - usedUnits) * unit / 2

            for (keyIndex, button) in row.enumerated() {
                let slot = button.key.widthUnits * unit
                let frame = CGRect(x: x + keyGap / 2, y: y, width: max(0, slot - keyGap), height: rowHeight)
                button.frame = frame

                // Outer keys take touches all the way to the keyboard's edges.
                button.hitOutset = UIEdgeInsets(
                    top: rowIndex == 0 ? frame.minY : rowGap / 2,
                    left: keyIndex == 0 ? frame.minX : keyGap / 2,
                    bottom: rowIndex == rows.count - 1 ? bounds.height - frame.maxY : rowGap / 2,
                    right: keyIndex == row.count - 1 ? bounds.width - frame.maxX : keyGap / 2
                )
                x += slot
            }
            y += rowHeight + rowGap
        }
    }
}

extension KeyboardView: UIGestureRecognizerDelegate {
    /// Only the space bar and letters with accents take part in long-press, so holding
    /// delete still auto-repeats and every other key behaves normally.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let button = button(at: touch.location(in: self)) else { return false }
        switch button.key.kind {
        case .space:
            return true
        case .character(let value):
            return KeyboardLayout.accentVariants[value] != nil
        default:
            return false
        }
    }
}
