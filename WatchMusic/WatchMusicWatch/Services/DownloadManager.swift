import Foundation

@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published private(set) var downloadedSongs: [Song] = []
    @Published var downloadingIDs: Set<String> = []
    @Published var lastError: String?

    private let metadataFileName = "downloaded_songs.json"
    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private init() {
        loadMetadata()
    }

    func isDownloaded(id: String) -> Bool {
        FileManager.default.fileExists(atPath: audioFileURL(for: id).path)
    }

    func audioFileURL(for id: String) -> URL {
        documentsURL.appendingPathComponent("\(id).m4a")
    }

    func download(_ song: Song) async {
        guard !isDownloaded(id: song.id), !downloadingIDs.contains(song.id) else { return }
        downloadingIDs.insert(song.id)
        defer { downloadingIDs.remove(song.id) }
        do {
            let data = try await NetworkService.shared.downloadAudioData(for: song)
            try data.write(to: audioFileURL(for: song.id))
            downloadedSongs.append(song)
            saveMetadata()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func delete(_ song: Song) {
        try? FileManager.default.removeItem(at: audioFileURL(for: song.id))
        downloadedSongs.removeAll { $0.id == song.id }
        saveMetadata()
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(downloadedSongs) {
            try? data.write(to: documentsURL.appendingPathComponent(metadataFileName))
        }
    }

    private func loadMetadata() {
        let url = documentsURL.appendingPathComponent(metadataFileName)
        guard let data = try? Data(contentsOf: url),
              let songs = try? JSONDecoder().decode([Song].self, from: data) else { return }
        // Filter out any entries whose audio file went missing (e.g. after an app reinstall).
        downloadedSongs = songs.filter { isDownloaded(id: $0.id) }
    }
}
