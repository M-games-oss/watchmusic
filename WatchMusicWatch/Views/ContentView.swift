import SwiftUI

struct ContentView: View {
    @StateObject private var player = AudioPlayerManager.shared
    @StateObject private var downloads = DownloadManager.shared

    var body: some View {
        TabView {
            SearchView()
            LibraryView()
            PlayerView()
            SettingsView()
        }
        .tabViewStyle(.page)
        .environmentObject(player)
        .environmentObject(downloads)
    }
}
