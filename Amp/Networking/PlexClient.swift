import Foundation

enum PlexError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case decoding(Error)
    case noServer

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid Plex URL."
        case .badStatus(let code): "Plex returned status \(code)."
        case .decoding(let error): "Failed to read Plex response: \(error.localizedDescription)"
        case .noServer: "No Plex server configured."
        }
    }
}

@MainActor
@Observable
final class PlexClient {
    static let clientIdentifier = "amp-ios"

    private(set) var server: PlexServer?

    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func configure(with server: PlexServer) {
        self.server = server
    }

    // MARK: - Auth

    func requestPin() async throws -> PlexPinsResponse {
        try await send(
            path: "/api/v2/pins",
            method: "POST",
            base: URL(string: "https://plex.tv")!,
            headers: [
                "X-Plex-Client-Identifier": Self.clientIdentifier,
                "X-Plex-Product": "Amp",
                "Accept": "application/json",
            ],
            authorized: false
        )
    }

    func pollPin(id: Int) async throws -> String? {
        struct PinStatus: Codable { let authToken: String? }
        let status: PinStatus = try await send(
            path: "/api/v2/pins/\(id)",
            method: "GET",
            base: URL(string: "https://plex.tv")!,
            headers: [
                "X-Plex-Client-Identifier": Self.clientIdentifier,
                "Accept": "application/json",
            ],
            authorized: false
        )
        return status.authToken
    }

    func fetchResources(token: String) async throws -> [PlexResource] {
        struct Response: Codable { let resources: [PlexResource]? }
        let response: Response = try await send(
            path: "/api/v2/resources?includeHttps=1&includeRelay=1",
            method: "GET",
            base: URL(string: "https://plex.tv")!,
            headers: [
                "X-Plex-Token": token,
                "X-Plex-Client-Identifier": Self.clientIdentifier,
                "Accept": "application/json",
            ],
            authorized: false
        )
        return response.resources ?? []
    }

    // MARK: - Library

    func artists(sectionID: String) async throws -> [PlexArtist] {
        let container: PlexMediaContainer<PlexArtist> = try await get(
            "/library/sections/\(sectionID)/all?type=8&sort=titleSort"
        )
        return container.Metadata ?? []
    }

    func albums(sectionID: String, artist: PlexArtist) async throws -> [PlexAlbum] {
        let container: PlexMediaContainer<PlexAlbum> = try await get(
            "/library/sections/\(sectionID)/all?type=9&artist.id=\(artist.ratingKey)"
        )
        return container.Metadata ?? []
    }

    func tracks(sectionID: String, album: PlexAlbum) async throws -> [PlexTrack] {
        let container: PlexMediaContainer<PlexTrack> = try await get(
            "/library/sections/\(sectionID)/all?type=10&album.id=\(album.ratingKey)"
        )
        return (container.Metadata ?? []).sorted { ($0.index ?? 0) < ($1.index ?? 0) }
    }

    func musicSections() async throws -> [(id: String, title: String)] {
        struct Section: Codable { let key: String; let title: String; let type: String? }
        let container: PlexMediaContainer<Section> = try await get("/library/sections")
        return (container.Metadata ?? [])
            .filter { $0.type == "artist" }
            .map { ($0.key, $0.title) }
    }

    func thumbURL(path: String, width: Int = 400, height: Int = 400) -> URL? {
        guard let server else { return nil }
        var components = URLComponents(
            url: server.baseURL.appendingPathComponent("/photo/:/transcode/universal/start"),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = [
            URLQueryItem(name: "url", value: path),
            URLQueryItem(name: "width", value: "\(width)"),
            URLQueryItem(name: "height", value: "\(height)"),
            URLQueryItem(name: "X-Plex-Token", value: server.token),
        ]
        return components?.url
    }

    // MARK: - Transport

    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let server else { throw PlexError.noServer }
        return try await send(
            path: path,
            method: "GET",
            base: server.baseURL,
            headers: server.headers,
            authorized: true
        )
    }

    private func send<T: Decodable>(
        path: String,
        method: String,
        base: URL,
        headers: [String: String],
        authorized: Bool
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: base) else { throw PlexError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PlexError.invalidURL }
        guard (200..<300).contains(http.statusCode) else {
            throw PlexError.badStatus(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PlexError.decoding(error)
        }
    }
}
