import UIKit

/// The keyboard's root view. Adopting `UIInputViewAudioFeedback` is how iOS lets a
/// keyboard play the standard key click, which follows the user's own
/// Settings › Sounds & Haptics › Keyboard Feedback › Sound switch and the silent switch.
final class KeyboardInputView: UIInputView, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }
}

/// Key-press sound and haptics.
///
/// Haptics only run when the user has turned on "Allow Full Access", because iOS
/// does not let keyboards vibrate without it. Full Access is used for nothing else:
/// NumRow has no networking, storage or analytics code either way.
final class KeyFeedback {
    private var haptics: UIImpactFeedbackGenerator?

    func keyPressed(hasFullAccess: Bool) {
        // iOS decides whether this is audible (Keyboard Feedback › Sound, silent switch).
        UIDevice.current.playInputClick()

        guard hasFullAccess else {
            haptics = nil
            return
        }
        if haptics == nil {
            haptics = UIImpactFeedbackGenerator(style: .light)
        }
        haptics?.impactOccurred()
        haptics?.prepare()   // keeps the next tap's vibration instant
    }
}
