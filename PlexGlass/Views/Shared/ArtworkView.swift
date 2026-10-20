import SwiftUI

struct ArtworkView: View {
    @Environment(PlexClient.self) private var client
    let path: String?
    var cornerRadius: CGFloat = 12

    var body: some View {
        Group {
            if let path, let url = client.thumbURL(path: path) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    default:
                        ZStack { placeholder; ProgressView() }
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
