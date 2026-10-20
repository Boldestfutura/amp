import SwiftUI

struct LibraryRootView: View {
    @Environment(PlexClient.self) private var client
    @Environment(PlayerModel.self) private var player
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var sections: [LibrarySection] = []
    @State private var artists: [PlexArtist] = []
    @State private var selectedArtist: PlexArtist?
    @State private var selectedAlbum: PlexAlbum?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if sizeClass == .regular {
                NavigationSplitView {
                    sidebar
                } content: {
                    artistList
                } detail: {
                    albumDetail
                }
            } else {
                NavigationStack {
                    artistList
                        .navigationDestination(for: PlexArtist.self) { artist in
                            AlbumListView(artist: artist)
                        }
                }
            }
        }
        .task { await load() }
        .overlay(alignment: .bottom) { NowPlayingBar() }
    }

    private var sidebar: some View {
        List(sections, selection: $selectedArtist) { section in
            Section("Music") {
                Label(section.title, systemImage: "music.note.list")
            }
        }
        .navigationTitle("Library")
    }

    private var artistList: some View {
        List(artists) { artist in
            ArtistRow(artist: artist)
                .onTapGesture {
                    if sizeClass == .regular {
                        selectedArtist = artist
                        selectedAlbum = nil
                    }
                }
        }
        .overlay {
            if isLoading { ProgressView() }
            if let errorMessage {
                ContentUnavailableView("Couldn't load library", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
            }
        }
        .navigationTitle("Artists")
    }

    @ViewBuilder
    private var albumDetail: some View {
        if let selectedArtist {
            AlbumListView(artist: selectedArtist)
        } else {
            ContentUnavailableView("Select an artist", systemImage: "music.mic")
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        if DemoData.isEnabled {
            sections = [LibrarySection(id: "1", title: "Music")]
            artists = DemoData.artists
            return
        }
        do {
            let found = try await client.musicSections()
            sections = found.map { LibrarySection(id: $0.id, title: $0.title) }
            guard let first = found.first else { return }
            artists = try await client.artists(sectionID: first.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct LibrarySection: Identifiable, Hashable {
    let id: String
    let title: String
}

struct ArtistRow: View {
    @Environment(PlexClient.self) private var client
    let artist: PlexArtist

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(path: artist.thumb, cornerRadius: 12)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.title).font(.body.weight(.medium))
                Text("Artist").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
