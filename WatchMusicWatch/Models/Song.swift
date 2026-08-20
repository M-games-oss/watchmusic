import Foundation

/// Matches the JSON your yt-dlp server returns from /api/search.
/// Adjust CodingKeys if your server (e.g. VinylWave-style Express backend) uses different field names.
struct Song: Identifiable, Codable, Hashable {
    let id: String          // YouTube video ID
    let title: String
    let artist: String?
    let thumbnailURL: String?
    let duration: Int       // seconds

    enum CodingKeys: String, CodingKey {
        case id, title, artist, duration
        case thumbnailURL = "thumbnail"
    }

    var durationLabel: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
