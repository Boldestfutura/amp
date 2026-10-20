import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var appModel

    @State private var pin: PlexPinsResponse?
    @State private var status: Status = .idle
    @State private var manualToken = ""
    @State private var showManual = false

    enum Status: Equatable {
        case idle, loading, waiting, error(String)
    }

    var body: some View {
        ZStack {
            gradient
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse)

                VStack(spacing: 8) {
                    Text("PlexGlass").font(.largeTitle.bold())
                    Text("A Liquid Glass music client for your Plex library")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("v0.1.0 beta")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                content

                Spacer()
            }
            .padding(28)
            .frame(maxWidth: 480)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch status {
        case .idle:
            VStack(spacing: 12) {
                Button("Sign in with Plex") { Task { await beginSignIn() } }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                Button("Enter server manually") { showManual = true }
                    .buttonStyle(.glass)
            }

        case .loading:
            ProgressView("Requesting PIN…")

        case .waiting:
            if let pin {
                GlassCard(cornerRadius: 20) {
                    VStack(spacing: 10) {
                        Text("Enter this code on plex.tv/link")
                            .font(.subheadline)
                        Text(pin.code)
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .textSelection(.enabled)
                        ProgressView().controlSize(.small)
                        Text("Waiting for authorization…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                }
            }

        case .error(let message):
            VStack(spacing: 12) {
                GlassCard(cornerRadius: 18) {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .padding(16)
                }
                Button("Try again") { status = .idle }
                    .buttonStyle(.glass)
            }
        }
    }

    private var gradient: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.45), Color(.systemBackground)],
            startPoint: .topLeading,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func beginSignIn() async {
        status = .loading
        do {
            let response = try await appModel.client.requestPin()
            pin = response
            status = .waiting
            await pollForToken(id: response.id)
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    private func pollForToken(id: Int) async {
        for _ in 0..<120 {
            try? await Task.sleep(for: .seconds(2))
            guard let token = try? await appModel.client.pollPin(id: id), !token.isEmpty else { continue }
            await finishSignIn(token: token)
            return
        }
        status = .error("Timed out waiting for authorization.")
    }

    private func finishSignIn(token: String) async {
        do {
            let resources = try await appModel.client.fetchResources(token: token)
            let musicServers = resources.filter { $0.provides?.contains("server") == true }
            guard let resource = musicServers.first,
                  let connection = resource.connections?.first(where: { $0.local == true })
                    ?? resource.connections?.first,
                  let address = connection.address,
                  let port = connection.port else {
                status = .error("No Plex Media Server found on your account.")
                return
            }
            let server = PlexServer(
                name: resource.name,
                host: address,
                port: port,
                scheme: connection.protocol ?? "http",
                token: resource.accessToken ?? token
            )
            appModel.session.authenticate(token: server.token, server: server)
            appModel.apply(server: server)
        } catch {
            status = .error(error.localizedDescription)
        }
    }
}
