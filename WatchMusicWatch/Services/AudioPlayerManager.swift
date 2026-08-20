import Foundation
import AVFoundation

@MainActor
final class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()

    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var duration: Double = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var queue: [Song] = []

    func play(_ song: Song, queue: [Song] = []) {
        guard DownloadManager.shared.isDownloaded(id: song.id) else { return }
        let url = DownloadManager.shared.audioFileURL(for: song.id)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()

            currentSong = song
            duration = player?.duration ?? 0
            progress = 0
            isPlaying = true
            self.queue = queue.isEmpty ? [song] : queue
            startTimer()
        } catch {
            print("Playback failed: \(error)")
        }
    }

    func togglePlayPause() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(to value: Double) {
        player?.currentTime = value
        progress = value
    }

    func skipForward() {
        guard let current = currentSong,
              let idx = queue.firstIndex(where: { $0.id == current.id }),
              idx + 1 < queue.count else { return }
        play(queue[idx + 1], queue: queue)
    }

    func skipBackward() {
        guard let current = currentSong,
              let idx = queue.firstIndex(where: { $0.id == current.id }),
              idx - 1 >= 0 else { return }
        play(queue[idx - 1], queue: queue)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            Task { @MainActor in
                self.progress = player.currentTime
            }
        }
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.skipForward()
        }
    }
}
