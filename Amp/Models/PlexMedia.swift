import Foundation

struct PlexMediaContainer<Element: Codable>: Codable {
    let size: Int?
    let totalSize: Int?
    let offset: Int?
    let Metadata: [Element]?
    let MediaContainer: PlexMediaContainer<Element>?
}

struct PlexArtist: Codable, Identifiable, Hashable {
    let ratingKey: String
    let key: String
    let title: String
    let thumb: String?
    let art: String?

    var id: String { ratingKey }
}

struct PlexAlbum: Codable, Identifiable, Hashable {
    let ratingKey: String
    let key: String
    let title: String
    let parentTitle: String?
    let thumb: String?
    let art: String?
    let year: Int?

    var id: String { ratingKey }
}

struct PlexTrack: Codable, Identifiable, Hashable {
    let ratingKey: String
    let key: String
    let title: String
    let grandparentTitle: String?
    let parentTitle: String?
    let index: Int?
    let parentIndex: Int?
    let duration: Int?
    let thumb: String?
    let Media: [PlexMedia]?

    var id: String { ratingKey }

    var partKey: String? {
        Media?.first?.Part?.first?.key
    }

    var durationSeconds: Double {
        Double(duration ?? 0) / 1000.0
    }
}

struct PlexMedia: Codable, Hashable {
    let id: Int?
    let bitrate: Int?
    let audioCodec: String?
    let Part: [PlexPart]?
}

struct PlexPart: Codable, Hashable {
    let id: Int?
    let key: String
    let duration: Int?
    let container: String?
}
