import SwiftUI

struct AlbumListView: View {
    @Environment(PlexClient.self) private var client
    @Environment(PlayerModel.self) private var player
    @Environment(\.horizontalSizeClass) private var sizeClass

    let artist: PlexArtist

    @State private var albums: [PlexAlbum] = []
    @State private var isLoading = true

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(albums) { album in
                        NavigationLink(value: album) {
                            AlbumCard(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .background(backgroundGradient)
        .navigationTitle(artist.title)
        .navigationDestination(for: PlexAlbum.self) { album in
            TrackListView(artist: artist, album: album)
        }
        .task { await load() }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.25), .clear],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        if DemoData.isEnabled {
            albums = DemoData.albums
            return
        }
        do {
            let sections = try await client.musicSections()
            guard let first = sections.first else { return }
            albums = try await client.albums(sectionID: first.id, artist: artist)
        } catch {
            albums = []
        }
    }
}

struct AlbumCard: View {
    let album: PlexAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkView(path: album.thumb, cornerRadius: 16)
                .aspectRatio(1, contentMode: .fit)
                .shadow(radius: 8, y: 4)
            Text(album.title).font(.subheadline.weight(.semibold)).lineLimit(1)
            if let year = album.year {
                Text(String(year)).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
