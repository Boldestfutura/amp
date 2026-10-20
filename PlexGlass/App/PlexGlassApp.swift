import SwiftUI

@main
struct PlexGlassApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .environment(appModel.client)
                .environment(appModel.session)
                .environment(appModel.player)
        }
    }
}

@MainActor
@Observable
final class AppModel {
    let client = PlexClient()
    let session = SessionStore()
    var player: PlayerModel

    private let fallbackServer = PlexServer(
        name: "Unconfigured", host: "127.0.0.1", port: 32400,
        scheme: "http", token: ""
    )

    init() {
        if DemoData.isEnabled {
            client.configure(with: DemoData.server)
            player = PlayerModel(server: DemoData.server)
            session.enableDemo()
            return
        }
        player = PlayerModel(server: session.server ?? fallbackServer)
        if let server = session.server {
            client.configure(with: server)
        }
    }

    func apply(server: PlexServer) {
        client.configure(with: server)
        player.updateServer(server)
    }
}
