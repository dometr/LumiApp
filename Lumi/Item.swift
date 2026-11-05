import Foundation

nonisolated enum ItemKind: String, CaseIterable, Identifiable, Sendable {
    case movies = "Movies"
    case music = "Music"
    case books = "Books"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .movies: return "film"
        case .music: return "music.note"
        case .books: return "book.closed"
        }
    }
}

nonisolated struct Item: Identifiable, Sendable {
    let id = UUID()
    var photo: String = ""          // legacy: name of an image in Assets
    var name: String
    var author: String = ""
    var year: String = ""
    var details: String = ""
    var rating: String = ""
    var watched: Bool = false
    var imageURL: String = ""       // poster / cover / artwork from the APIs
    var kind: String = ""           // "Movies" / "Music" / "Books"
    var countryCode: String = ""    // ISO alpha-2, e.g. "IT"
    var externalID: String = ""     // "tmdb-123", "itunes-456", "ol-/works/..."
}
