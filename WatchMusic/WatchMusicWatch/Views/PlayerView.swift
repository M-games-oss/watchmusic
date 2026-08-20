import SwiftUI

struct PlayerView: View {
    @EnvironmentObject var player: AudioPlayerManager
    @State private var crownValue: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            if let song = player.currentSong {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: .purple.opacity(0.4), radius: 6, y: 3)
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }
                .padding(.top, 2)

                Text(song.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                if let artist = song.artist {
                    Text(artist)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                ProgressView(value: player.progress, total: max(player.duration, 1))
                    .tint(.purple)
                    .padding(.horizontal, 4)

                HStack(spacing: 22) {
                    Button { player.skipBackward() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                    }
                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                    }
                    Button { player.skipForward() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            } else {
                Spacer()
                Image(systemName: "music.note.list")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                Text("Nothing Playing")
                    .foregroundStyle(.secondary)
                Text("Pick a song from Library")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 4)
        .focusable(player.currentSong != nil)
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: max(player.duration, 1),
            by: 1,
            sensitivity: .medium,
            isContinuous: false
        )
        .onChange(of: crownValue) { _, newValue in
            player.seek(to: newValue)
        }
        .onAppear { crownValue = player.progress }
    }
}
