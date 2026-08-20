import SwiftUI

@main
struct WatchMusicCompanionApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Image(systemName: "applewatch")
                    .font(.system(size: 40))
                Text("WatchMusic lives on your Apple Watch")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("Open the Watch app on your iPhone to install it, then launch it from your wrist.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
