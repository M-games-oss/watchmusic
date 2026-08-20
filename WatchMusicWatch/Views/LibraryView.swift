import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var downloads: DownloadManager
    @EnvironmentObject var player: AudioPlayerManager

    var body: some View {
        NavigationStack {
            List {
                if downloads.downloadedSongs.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                        Text("No downloads yet")
                            .foregroundStyle(.secondary)
                        Text("Search for a song and tap the download icon.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    ForEach(downloads.downloadedSongs) { song in
                        SongRowView(song: song, queueForPlayback: downloads.downloadedSongs)
                            .swipeActions {
                                Button(role: .destructive) {
                                    downloads.delete(song)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Library")
        }
    }
}
