import Foundation

/// Expected server contract (adjust paths to match your existing yt-dlp server):
///   GET  /api/search?q={query}      -> [Song] as JSON
///   GET  /api/download/{videoId}    -> raw audio bytes (m4a/mp3)
///
/// If your server uses HTTP Basic Auth (like VinylWave), set the username/password
/// in Settings on the watch and this will attach the Authorization header automatically.
final class NetworkService {
    static let shared = NetworkService()
    private init() {}

    private var baseURL: String {
        let raw = UserDefaults.standard.string(forKey: "serverURL") ?? ""
        return raw.hasSuffix("/") ? String(raw.dropLast()) : raw
    }
    private var username: String { UserDefaults.standard.string(forKey: "authUsername") ?? "" }
    private var password: String { UserDefaults.standard.string(forKey: "authPassword") ?? "" }

    private func authorizedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        if !username.isEmpty {
            let credentials = "\(username):\(password)"
            let encoded = Data(credentials.utf8).base64EncodedString()
            request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func search(query: String) async throws -> [Song] {
        guard !baseURL.isEmpty else { throw NetworkError.noServerConfigured }
        guard var components = URLComponents(string: "\(baseURL)/api/search") else {
            throw NetworkError.badURL
        }
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components.url else { throw NetworkError.badURL }

        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url))
        try Self.validate(response)
        return try JSONDecoder().decode([Song].self, from: data)
    }

    func downloadAudioData(for song: Song) async throws -> Data {
        guard !baseURL.isEmpty else { throw NetworkError.noServerConfigured }
        guard let url = URL(string: "\(baseURL)/api/download/\(song.id)") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url))
        try Self.validate(response)
        return data
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NetworkError.serverError
        }
    }
}

enum NetworkError: LocalizedError {
    case noServerConfigured, badURL, serverError

    var errorDescription: String? {
        switch self {
        case .noServerConfigured: return "Set your server URL in Settings first."
        case .badURL: return "That server URL doesn't look right."
        case .serverError: return "The server returned an error."
        }
    }
}
