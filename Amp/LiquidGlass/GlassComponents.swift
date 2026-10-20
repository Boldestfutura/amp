import SwiftUI

/// A floating Liquid Glass surface that adopts the native iOS 26 glass material.
/// Uses `glassEffect(_:in:)` with the `.regular` variant by default.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 24
    var tint: Color?
    var interactive: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
    }

    private var glass: Glass {
        var effect: Glass = .regular
        if let tint { effect = effect.tint(tint) }
        if interactive { effect = effect.interactive() }
        return effect
    }
}

/// A compact glass pill, e.g. for metadata chips.
struct GlassPill: View {
    let systemImage: String?
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }
}

/// Round, interactive glass transport control.
struct GlassTransportButton: View {
    let systemImage: String
    var size: CGFloat = 44
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        let button = Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .frame(width: size, height: size)
        }
        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }
}
