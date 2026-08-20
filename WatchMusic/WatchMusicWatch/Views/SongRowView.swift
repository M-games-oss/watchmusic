import SwiftUI

struct SongRowView: View {
    let song: Song
    var queueForPlayback: [Song] = []

    @EnvironmentObject var downloads: DownloadManager
    @EnvironmentObject var player: AudioPlayerManager

    private var isDownloaded: Bool { downloads.isDownloaded(id: song.id) }
    private var isDownloading: Bool { downloads.downloadingIDs.contains(song.id) }
    private var isCurrentlyPlaying: Bool { player.currentSong?.id == song.id }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isCurrentlyPlaying ? Color.purple : .primary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if let artist = song.artist {
                        Text(artist)
                            .lineLimit(1)
                    }
                    Text("· \(song.durationLabel)")
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            statusButton
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isDownloaded {
                player.play(song, queue: queueForPlayback.isEmpty ? downloads.downloadedSongs : queueForPlayback)
            }
        }
    }

    @ViewBuilder
    private var statusButton: some View {
        if isDownloading {
            ProgressView()
                .frame(width: 20, height: 20)
        } else if isDownloaded {
            Image(systemName: isCurrentlyPlaying ? "waveform" : "checkmark.circle.fill")
                .foregroundStyle(isCurrentlyPlaying ? .purple : .green)
        } else {
            Button {
                Task { await downloads.download(song) }
            } label: {
                Image(systemName: "arrow.down.circle")
            }
            .buttonStyle(.plain)
        }
    }
}
