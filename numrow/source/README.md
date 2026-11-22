# NumRow Keyboard

Free and open source (MIT License). Coming free to the App Store. You can also build it yourself from this folder. Overview: https://huntsmansec.github.io/numrow/ · Privacy policy: https://huntsmansec.github.io/numrow/privacy.html

An English (US) iPhone keyboard with a **number row always on top**. It has no Full Access, no network access and no data collection.

```
 1  2  3  4  5  6  7  8  9  0     ← always visible, in every mode
 q  w  e  r  t  y  u  i  o  p
  a  s  d  f  g  h  j  k  l
 ⇧   z  x  c  v  b  n  m   ⌫
123  🌐       space      return
```

## Project layout

| Path | What it is |
|---|---|
| `NumRowKeyboard/` | Container app (SwiftUI): setup steps, a test field, privacy summary |
| `Keyboard/KeyboardViewController.swift` | Extension entry point: typing, shift/caps lock, auto-caps, double-space period, delete repeat |
| `Keyboard/KeyboardView.swift` | Proportional layout that fits every iPhone, portrait and landscape |
| `Keyboard/KeyButton.swift` | Key drawing, light/dark colors, VoiceOver labels, enlarged touch targets |
| `Keyboard/KeyboardLayout.swift` | Rows for letters / numbers / symbols |
| `*/PrivacyInfo.xcprivacy` | Privacy manifests: no tracking, no collected data |

## Build and run

1. Install **Xcode** from the Mac App Store, then open it once to finish setup.
2. Open `NumRowKeyboard.xcodeproj`.
3. For **both** targets, go to Signing & Capabilities and pick your Team. If you are building your own copy, change the bundle IDs from `com.huntsmansec.numrowkeyboard` to your own reverse-domain ID. The extension's ID must start with the app's ID (for example `com.yourname.numrow` and `com.yourname.numrow.keyboard`).
4. Choose an iPhone simulator and press Run (⌘R).
5. In the simulator, go to Settings → General → Keyboard → Keyboards → Add New Keyboard → **NumRow**. Open the app's text field, hold 🌐 and pick NumRow.

Requirements: iOS 16+, iPhone. Builds with Xcode 15 or newer.

## Security and privacy design

- **No Full Access.** `RequestsOpenAccess = NO`. iOS sandboxes the keyboard, so it can't use the network, read the clipboard or share data with the app. This is enforced by the operating system, not just a promise.
- **No keystroke storage or logging.** There's no `print`/`os_log`, no files, no UserDefaults, no database.
- **Minimal text access.** The keyboard reads only the text just before the cursor, in memory, for auto-capitalization and the double-space period.
- **No third-party code.** No SDKs, analytics, ads or packages, so nothing in the supply chain needs auditing.
- **Secure fields are protected by iOS.** Password and one-time-code fields always switch to Apple's keyboard.
- **Accessibility.** Every key has a VoiceOver label and the keyboard-key trait.

If you ever add features that need Full Access (haptics, sync, cloud themes), treat that as a major privacy change. Update the privacy policy and the App Store privacy label, and keep the keyboard fully usable with Full Access off (App Review guideline 4.4.1).

## Before submitting to the App Store

- [ ] Apple Developer Program membership ($99/year)
- [ ] Your Team and bundle IDs set on both targets
- [ ] A 1024×1024 app icon in `Assets.xcassets/AppIcon` (it's an empty placeholder now)
- [ ] Test on a real device: portrait and landscape, light and dark, VoiceOver, an iPhone SE-sized simulator and a Pro Max-sized one
- [ ] Privacy policy URL (required for keyboards). Summary: "NumRow does not collect, store or transmit any data."
- [ ] App Store Connect privacy label: **Data Not Collected**
- [ ] Export compliance is already declared (`ITSAppUsesNonExemptEncryption = NO`)
- [ ] Product → Archive → Distribute App → App Store Connect

## Known iOS limits (apply to every third-party keyboard)

- Password, secure and phone-pad fields always use Apple's keyboard.
- Some apps (banking, enterprise) block custom keyboards entirely.
- No dictation microphone, no key-press haptics without Full Access, and the extension has a tight memory limit (about 50–70 MB).

## Built-in typing features

- Compact number row always on top (25% shorter than letter rows); letters, `123` and `#+=` layers
- Autocorrect on space or punctuation, with a three-slot suggestion bar: keep what you typed (“teh”), the correction (**the**), or a completion. Uses Apple's on-device spell checker; nothing is learned or saved. Turns itself off in email, URL and number fields, and in any field where the app disables autocorrect
- Contact names and your Text Replacement phrases are never autocorrected
- Auto-capitalization, shift and caps lock (double-tap shift), hold delete to repeat
- Double-tap space types ". "
- Hold a letter (a, c, e, i, l, n, o, s, u, y, z) for accents: slide to é, ñ, ü… and release
- Hold the space bar to use it as a trackpad: slide left/right to move the cursor
- Your Text Replacement shortcuts (Settings › General › Keyboard › Text Replacement) work, e.g. "omw" → "On my way!"
- Light and dark mode, VoiceOver labels

## Possible next features

Next-word prediction (suggestions before you start typing a word), key-press preview bubbles, and vertical cursor movement on the trackpad. iOS only lets keyboards move the cursor left/right by characters, so up/down would have to be approximated.
