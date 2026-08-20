import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [Song] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @EnvironmentObject var downloads: DownloadManager
    @EnvironmentObject var player: AudioPlayerManager

    var body: some View {
        NavigationStack {
            List {
                TextField("Search songs...", text: $query)
                    .onSubmit { Task { await search() } }

                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                ForEach(results) { song in
                    SongRowView(song: song, queueForPlayback: results)
                }
            }
            .navigationTitle("Search")
        }
    }

    private func search() async {
        guard !query.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            results = try await NetworkService.shared.search(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
