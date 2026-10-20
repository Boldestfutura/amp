import SwiftUI

struct NowPlayingView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(\.dismiss) private var dismiss
    @Namespace private var namespace

    @State private var scrubValue: Double = 0
    @State private var isScrubbing = false

    var body: some View {
        ZStack {
            backdrop
            ScrollView {
                VStack(spacing: 28) {
                    header
                    artwork
                    titleBlock
                    scrubber
                    transport
                    volumeRow
                }
                .padding(24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .presentationBackground(.clear)
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.5), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down").font(.headline)
            }
            .buttonStyle(.glass)
            Spacer()
            GlassPill(systemImage: "music.note", text: "Now Playing")
            Spacer()
            Button { } label: {
                Image(systemName: "ellipsis").font(.headline)
            }
            .buttonStyle(.glass)
        }
    }

    private var artwork: some View {
        ArtworkView(path: player.currentTrack?.thumb, cornerRadius: 28)
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 380)
            .shadow(radius: 30, y: 16)
            .glassEffectID("artwork", in: namespace)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(player.currentTrack?.title ?? "Not Playing")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(player.currentTrack?.grandparentTitle ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var scrubber: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubValue : player.currentTime },
                    set: { scrubValue = $0 }
                ),
                in: 0...max(player.duration, 1),
                onEditingChanged: { editing in
                    if editing {
                        isScrubbing = true
                    } else {
                        player.seek(to: scrubValue)
                        isScrubbing = false
                    }
                }
            )
            .tint(.primary)
            HStack {
                Text(timeString(isScrubbing ? scrubValue : player.currentTime))
                Spacer()
                Text(timeString(player.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private var transport: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 20) {
                GlassTransportButton(systemImage: "backward.fill") { player.previous() }
                GlassTransportButton(
                    systemImage: player.isPlaying ? "pause.fill" : "play.fill",
                    size: 72,
                    prominent: true
                ) { player.togglePlayPause() }
                .glassEffectID("mainTransport", in: namespace)
                GlassTransportButton(systemImage: "forward.fill") { player.next() }
            }
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 16) {
            GlassTransportButton(systemImage: player.isShuffled ? "shuffle" : "shuffle", size: 40) {
                player.isShuffled.toggle()
            }
            GlassTransportButton(systemImage: repeatIcon, size: 40) {
                player.repeatMode = nextRepeat(player.repeatMode)
            }
            Spacer()
            GlassPill(systemImage: "airplayaudio", text: "AirPlay")
        }
    }

    private var repeatIcon: String {
        player.repeatMode == .one ? "repeat.1" : "repeat"
    }

    private func nextRepeat(_ mode: PlayerModel.RepeatMode) -> PlayerModel.RepeatMode {
        switch mode {
        case .off: .all
        case .all: .one
        case .one: .off
        }
    }

    private func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
