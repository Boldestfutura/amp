import Foundation

struct PlexMediaContainer<Element: Codable>: Codable {
    let size: Int?
    let totalSize: Int?
    let offset: Int?
    let Metadata: [Element]?

    private enum CodingKeys: String, CodingKey {
        case size, totalSize, offset, Metadata
        case mediaContainer = "MediaContainer"
    }

    init(size: Int? = nil, totalSize: Int? = nil, offset: Int? = nil, Metadata: [Element]? = nil) {
        self.size = size
        self.totalSize = totalSize
        self.offset = offset
        self.Metadata = Metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nested = try container.decodeIfPresent(
            PlexMediaContainer<Element>.self,
            forKey: .mediaContainer
        )
        size = try container.decodeIfPresent(Int.self, forKey: .size) ?? nested?.size
        totalSize = try container.decodeIfPresent(Int.self, forKey: .totalSize) ?? nested?.totalSize
        offset = try container.decodeIfPresent(Int.self, forKey: .offset) ?? nested?.offset
        Metadata = try container.decodeIfPresent([Element].self, forKey: .Metadata) ?? nested?.Metadata
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(totalSize, forKey: .totalSize)
        try container.encodeIfPresent(offset, forKey: .offset)
        try container.encodeIfPresent(Metadata, forKey: .Metadata)
    }
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
