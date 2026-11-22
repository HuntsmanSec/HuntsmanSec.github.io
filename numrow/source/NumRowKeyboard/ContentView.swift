import SwiftUI

/// The container app: setup instructions, a test field and a plain-language privacy promise.
/// It has no network code, no analytics and no third-party dependencies.
struct ContentView: View {
    @State private var testText = ""
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SetupStep(number: 1, text: "Tap **Open Settings** below.")
                    SetupStep(number: 2, text: "Tap **Keyboards**, then turn on **NumRow**.")
                    SetupStep(number: 3, text: "In any app, tap and hold the \(Image(systemName: "globe")) key and choose **NumRow**.")
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                } header: {
                    Text("Set up")
                } footer: {
                    Text("Leave \"Allow Full Access\" off. NumRow doesn't need it.")
                }

                Section {
                    TextField("Type here to try it", text: $testText, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Try it")
                } footer: {
                    Text("Password fields, and many banking and e-wallet apps, always use Apple's keyboard. iOS switches over automatically to protect you.")
                }

                Section("Your privacy") {
                    PrivacyRow(
                        icon: "lock.shield",
                        title: "No Full Access",
                        detail: "iOS keeps the keyboard sealed off from the internet, your clipboard and other apps."
                    )
                    PrivacyRow(
                        icon: "eye.slash",
                        title: "Nothing is recorded",
                        detail: "What you type is never stored, logged or sent anywhere."
                    )
                    PrivacyRow(
                        icon: "chart.bar.xaxis",
                        title: "No tracking or analytics",
                        detail: "No ads, no accounts, no third-party code."
                    )
                }
            }
            .navigationTitle("NumRow Keyboard")
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let text: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.accentColor))
                .accessibilityHidden(true)
            Text(text)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PrivacyRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ContentView()
}
