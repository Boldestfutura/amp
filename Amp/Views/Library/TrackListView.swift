import SwiftUI

struct TrackListView: View {
    @Environment(PlexClient.self) private var client
    @Environment(PlayerModel.self) private var player

    let artist: PlexArtist
    let album: PlexAlbum

    @State private var tracks: [PlexTrack] = []
    @State private var isLoading = true

    var body: some View {
        List {
            Section {
                HStack(alignment: .bottom, spacing: 16) {
                    ArtworkView(path: album.thumb, cornerRadius: 18)
                        .frame(width: 140, height: 140)
                        .shadow(radius: 12, y: 6)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(album.title).font(.title2.bold())
                        Text(artist.title).font(.subheadline).foregroundStyle(.secondary)
                        Button {
                            if let first = tracks.first {
                                player.play(track: first, in: tracks)
                            }
                        } label: {
                            Label("Play", systemImage: "play.fill")
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(tracks.isEmpty)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    Button {
                        player.play(track: track, in: tracks)
                    } label: {
                        TrackRow(track: track, isCurrent: player.currentTrack == track)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay { if isLoading { ProgressView() } }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        if DemoData.isEnabled {
            tracks = DemoData.tracks
            return
        }
        do {
            let sections = try await client.musicSections()
            guard let first = sections.first else { return }
            tracks = try await client.tracks(sectionID: first.id, album: album)
        } catch {
            tracks = []
        }
    }
}

struct TrackRow: View {
    let track: PlexTrack
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isCurrent {
                Image(systemName: "waveform")
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.variableColor.iterative)
            } else {
                Text("\(track.index ?? 0)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title).font(.body.weight(isCurrent ? .semibold : .regular))
                if let parent = track.parentTitle {
                    Text(parent).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let duration = track.duration {
                Text(formatted(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatted(_ ms: Int) -> String {
        let total = ms / 1000
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
