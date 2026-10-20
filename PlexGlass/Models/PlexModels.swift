import Foundation

struct PlexServer: Codable, Identifiable, Hashable {
    let name: String
    let host: String
    let port: Int
    let scheme: String
    let token: String

    var id: String { "\(scheme)://\(host):\(port)" }
    var baseURL: URL { URL(string: "\(scheme)://\(host):\(port)")! }
    var headers: [String: String] { ["X-Plex-Token": token, "Accept": "application/json"] }
}

struct PlexResource: Codable, Identifiable, Hashable {
    let name: String
    let clientIdentifier: String?
    let provides: String?
    let accessToken: String?
    let connections: [PlexConnection]?

    var id: String { clientIdentifier ?? name }
}

struct PlexConnection: Codable, Hashable {
    let uri: String?
    let address: String?
    let port: Int?
    let local: Bool?
    let relay: Bool?
    let `protocol`: String?
}

struct PlexPinsResponse: Codable {
    let id: Int
    let code: String
}
