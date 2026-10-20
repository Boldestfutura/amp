import Foundation

/// Deterministic sample data used for SwiftUI previews and UI-test screenshots.
/// Enabled with the `-UITestDemoMode 1` launch argument or SwiftUI previews.
enum DemoData {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITestDemoMode")
    }

    static let server = PlexServer(
        name: "Demo Server", host: "127.0.0.1", port: 32400,
        scheme: "http", token: "demo"
    )

    static let artists: [PlexArtist] = [
        PlexArtist(ratingKey: "1", key: "/library/metadata/1", title: "Aphex Twin", thumb: nil, art: nil),
        PlexArtist(ratingKey: "2", key: "/library/metadata/2", title: "Boards of Canada", thumb: nil, art: nil),
        PlexArtist(ratingKey: "3", key: "/library/metadata/3", title: "Four Tet", thumb: nil, art: nil),
        PlexArtist(ratingKey: "4", key: "/library/metadata/4", title: "Burial", thumb: nil, art: nil),
    ]

    static let albums: [PlexAlbum] = [
        PlexAlbum(ratingKey: "10", key: "/library/metadata/10", title: "Selected Ambient Works", parentTitle: "Aphex Twin", thumb: nil, art: nil, year: 1992),
        PlexAlbum(ratingKey: "11", key: "/library/metadata/11", title: "Drukqs", parentTitle: "Aphex Twin", thumb: nil, art: nil, year: 2001),
        PlexAlbum(ratingKey: "12", key: "/library/metadata/12", title: "Music Has the Right to Children", parentTitle: "Boards of Canada", thumb: nil, art: nil, year: 1998),
    ]

    static let tracks: [PlexTrack] = [
        PlexTrack(ratingKey: "100", key: "/library/metadata/100", title: "Xtal", grandparentTitle: "Aphex Twin", parentTitle: "Selected Ambient Works", index: 1, parentIndex: 1, duration: 293000, thumb: nil, Media: []),
        PlexTrack(ratingKey: "101", key: "/library/metadata/101", title: "Tha", grandparentTitle: "Aphex Twin", parentTitle: "Selected Ambient Works", index: 2, parentIndex: 1, duration: 546000, thumb: nil, Media: []),
        PlexTrack(ratingKey: "102", key: "/library/metadata/102", title: "Pulsewidth", grandparentTitle: "Aphex Twin", parentTitle: "Selected Ambient Works", index: 3, parentIndex: 1, duration: 208000, thumb: nil, Media: []),
    ]
}
