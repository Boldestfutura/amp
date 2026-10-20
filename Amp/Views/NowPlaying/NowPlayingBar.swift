import SwiftUI

struct NowPlayingBar: View {
    @Environment(PlayerModel.self) private var player
    @Namespace private var glassNamespace
    @State private var expanded = false

    var body: some View {
        if let track = player.currentTrack {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    ArtworkView(path: track.thumb, cornerRadius: 8)
                        .frame(width: 40, height: 40)
                        .glassEffectID("artwork", in: glassNamespace)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                        Text(track.grandparentTitle ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }

                    Spacer()

                    GlassTransportButton(
                        systemImage: player.isPlaying ? "pause.fill" : "play.fill",
                        size: 38
                    ) { player.togglePlayPause() }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
            .onTapGesture { expanded = true }
            .sheet(isPresented: $expanded) {
                NowPlayingView()
            }
        }
    }
}
