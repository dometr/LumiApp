import Foundation

private nonisolated struct OLResponse: Decodable {
    struct Doc: Decodable {
        let key: String?
        let title: String
        let author_name: [String]?
        let first_publish_year: Int?
        let cover_i: Int?
        let ratings_average: Double?
        let subject: [String]?
    }
    let docs: [Doc]
}

private nonisolated struct TMDBResponse: Decodable {
    struct Movie: Decodable {
        let id: Int
        let title: String
        let overview: String?
        let poster_path: String?
        let release_date: String?
        let vote_average: Double?
        let original_title: String?
    }
    let results: [Movie]
}

private nonisolated struct TMDBDetail: Decodable {
    struct PC: Decodable { let iso_3166_1: String }
    let origin_country: [String]?
    let production_countries: [PC]?
}

private nonisolated struct ITResponse: Decodable {
    struct Track: Decodable {
        let trackId: Int?
        let trackName: String?
        let artistName: String?
        let collectionName: String?
        let artworkUrl100: String?
        let primaryGenreName: String?
        let releaseDate: String?
        let previewUrl: String?
    }
    let results: [Track]
}

// Remembers the cover found for each curated song or book. Saved on the phone, so after the first time it is instant.
private actor ArtworkCache {
    static let shared = ArtworkCache()
    private static let key = "artworkCache.v1"
    private var urls: [String: String]
    init() { urls = UserDefaults.standard.dictionary(forKey: Self.key) as? [String: String] ?? [:] }
    func url(for id: String) -> String? { urls[id] }
    func set(_ url: String, for id: String) {
        urls[id] = url
        UserDefaults.standard.set(urls, forKey: Self.key)
    }
}

// Remembers the Open Library work (page + cover) found for each curated book
private actor BookWorkCache {
    static let shared = BookWorkCache()
    private var works: [String: (key: String, cover: String)] = [:]
    func work(for id: String) -> (key: String, cover: String)? { works[id] }
    func set(_ w: (key: String, cover: String), for id: String) { works[id] = w }
}

// Remembers what TMDB said about each award-winning film, so reopening the list does not search again
private actor MovieCache {
    static let shared = MovieCache()
    private var items: [String: Item] = [:]
    func item(for id: String) -> Item? { items[id] }
    func set(_ item: Item, for id: String) { items[id] = item }
}

// What the user picked in the filter screen
nonisolated struct ItemFilter: Hashable, Sendable {
    var genre: String? = nil
    var yearFrom: Int? = nil
    var yearTo: Int? = nil
    var country: String? = nil      // ISO alpha-2, e.g. "IT"

    var hasYears: Bool { yearFrom != nil || yearTo != nil }
    var isActive: Bool { genre != nil || hasYears || country != nil }
}

nonisolated enum APIService {

    // MARK: - Genres offered in the filter screen

    static func genres(for kind: ItemKind) -> [String] {
        switch kind {
        case .movies:
            return ["Action", "Adventure", "Animation", "Comedy", "Crime", "Documentary", "Drama",
                    "Family", "Fantasy", "History", "Horror", "Mystery", "Romance", "Sci-Fi",
                    "Thriller", "War", "Western"]
        case .music:
            return ["Pop", "Rock", "Hip-Hop/Rap", "R&B/Soul", "Dance", "Electronic", "Alternative",
                    "Jazz", "Classical", "Country", "Latin", "Reggae", "Blues", "Folk"]
        case .books:
            return ["Fiction", "Fantasy", "Science Fiction", "Mystery", "Romance", "Thriller",
                    "Horror", "History", "Biography", "Poetry", "Philosophy", "Classics"]
        }
    }

    private static let movieGenreIDs: [String: Int] = [
        "Action": 28, "Adventure": 12, "Animation": 16, "Comedy": 35, "Crime": 80,
        "Documentary": 99, "Drama": 18, "Family": 10751, "Fantasy": 14, "History": 36,
        "Horror": 27, "Mystery": 9648, "Romance": 10749, "Sci-Fi": 878,
        "Thriller": 53, "War": 10752, "Western": 37
    ]

    private static var thisYear: Int { Calendar.current.component(.year, from: Date()) }

    // MARK: - Public

    // List shown when the search field is empty. With a filter: only what matches it.
    // Ranked by CULTURAL VALUE, never by how popular something is right now:
    //  - Movies: a curated list of award winners (see MovieCanon)
    //  - Books:  a curated list of classics (see BookCanon)
    //  - Music:  a curated list of landmark songs (see MusicCanon): no free API ranks music by importance
    // "skipping" = ids already completed (the curated lists show only a few items at a time)
    static func essentials(_ kind: ItemKind, filter: ItemFilter = ItemFilter(), skipping: Set<String> = []) async -> [Item] {
        switch kind {
        case .movies:
            return await canonMovies(filter, skipping: skipping)
        case .music:
            return await canonMusic(filter, skipping: skipping)
        case .books:
            return await canonBooks(filter, skipping: skipping)
        }
    }

    // Anything the user types
    static func search(_ kind: ItemKind, query: String) async -> [Item] {
        switch kind {
        case .movies:
            return await tmdbList("search/movie", ["query": query, "include_adult": "false"])
        case .music:
            return await searchMusic(query)
        case .books:
            return await olSearch(query, sort: nil, limit: 30, requireCover: false)
        }
    }

    // Movies: TMDB tells us the country of origin (ISO alpha-2)
    static func movieCountry(externalID: String) async -> String? {
        let id = externalID.replacingOccurrences(of: "tmdb-", with: "")
        guard let d = await tmdbGet("movie/\(id)", [:]),
              let r = try? JSONDecoder().decode(TMDBDetail.self, from: d) else { return nil }
        return r.origin_country?.first ?? r.production_countries?.first?.iso_3166_1
    }

    // MARK: - Browsing with a filter

    // Movies: TMDB "discover" understands genre, release dates and country of origin
    private static func browseMovies(_ f: ItemFilter) async -> [Item] {
        var q = ["sort_by": "vote_average.desc"]
        if let g = f.genre, let id = movieGenreIDs[g] { q["with_genres"] = String(id) }
        if let c = f.country { q["with_origin_country"] = c }
        if let y = f.yearFrom { q["primary_release_date.gte"] = "\(y)-01-01" }
        if let y = f.yearTo { q["primary_release_date.lte"] = "\(y)-12-31" }
        // best rated first, but only films many people voted on (fewer votes needed when the list is narrow)
        let votes = f.country != nil ? 100 : (f.hasYears ? 500 : 1500)
        q["vote_count.gte"] = String(votes)

        let base = q
        async let p1 = tmdbList("discover/movie", base.merging(["page": "1"]) { $1 })
        async let p2 = tmdbList("discover/movie", base.merging(["page": "2"]) { $1 })
        return await p1 + p2
    }

    // MARK: - Helpers

    private static func url(_ base: String, _ q: [String: String]) -> URL? {
        var c = URLComponents(string: base)
        c?.queryItems = q.map { URLQueryItem(name: $0.key, value: $0.value) }
        return c?.url
    }

    private static func get(_ url: URL?, bearer: String = "", timeout: TimeInterval = 20) async -> Data? {
        guard let url else { return nil }
        var r = URLRequest(url: url)
        r.timeoutInterval = timeout
        r.setValue("LumiApp (student project)", forHTTPHeaderField: "User-Agent")
        if !bearer.isEmpty { r.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization") }
        guard let (d, resp) = try? await URLSession.shared.data(for: r),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return d
    }

    private static func yearOf(_ s: String?) -> String { String((s ?? "").prefix(4)) }

    private static func big(_ s: String?) -> String {
        (s ?? "").replacingOccurrences(of: "100x100", with: "400x400")
    }

    // MARK: - Movies (TMDB)

    private static func token() -> String {
        (Bundle.main.object(forInfoDictionaryKey: "TMDBToken") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
    }

    // Accepts the long "Read Access Token" and the short 32-char "API Key"
    private static func tmdbGet(_ path: String, _ q: [String: String]) async -> Data? {
        let t = token()
        guard !t.isEmpty, !t.hasPrefix("PASTE") else { return nil }
        var query = q
        query["language"] = "en-US"
        var bearer = ""
        if t.count > 60 { bearer = t } else { query["api_key"] = t }
        return await get(url("https://api.themoviedb.org/3/\(path)", query), bearer: bearer)
    }

    private static func tmdbList(_ path: String, _ q: [String: String]) async -> [Item] {
        guard let d = await tmdbGet(path, q),
              let r = try? JSONDecoder().decode(TMDBResponse.self, from: d) else { return [] }
        return r.results.map { m in
            let vote = m.vote_average ?? 0
            return Item(
                name: m.title,
                year: yearOf(m.release_date),
                details: m.overview ?? "",
                rating: vote > 0 ? String(format: "%.1f/10 (TMDB)", vote) : "",
                imageURL: m.poster_path.map { "https://image.tmdb.org/t/p/w500\($0)" } ?? "",
                kind: ItemKind.movies.rawValue,
                externalID: "tmdb-\(m.id)"
            )
        }
    }

    // MARK: - Music (Apple, no key)

    // Searches Apple's catalogue (store = a country's Apple Music store, nil = default)
    private static func searchMusic(_ query: String, limit: Int = 30, store: String? = nil) async -> [Item] {
        var q = ["term": query, "entity": "song", "limit": String(limit)]
        if let store { q["country"] = store.uppercased() }
        guard let d = await get(url("https://itunes.apple.com/search", q)),
              let r = try? JSONDecoder().decode(ITResponse.self, from: d) else { return [] }
        return r.results.compactMap { t in
            guard let name = t.trackName, let artist = t.artistName else { return nil }
            let details = [t.collectionName, t.primaryGenreName].compactMap { $0 }.joined(separator: " • ")
            return Item(
                name: name,
                author: artist,
                year: yearOf(t.releaseDate),
                details: details,
                imageURL: big(t.artworkUrl100),
                kind: ItemKind.music.rawValue,
                externalID: "itunes-\(t.trackId ?? 0)"
            )
        }
    }

    // MARK: - Music: curated list of landmark songs

    private static let canonPageSize = 30          // songs shown at a time
    private static let canonParallelSearches = 6   // cover art searches running together (Apple limits requests)

    // The songs come from MusicCanon (country, year and genre are known, so every filter works on them).
    // The list appears AT ONCE, with no internet needed. Covers are fetched afterwards, row by row
    // (see artwork(forCanonID:)), and are remembered on the phone.
    private static func canonMusic(_ f: ItemFilter, skipping: Set<String>) async -> [Item] {
        var items: [Item] = []
        for e in MusicCanon.matching(f, skipping: skipping).prefix(canonPageSize) {
            items.append(Item(
                name: e.title,
                author: e.artist,
                year: String(e.year),
                details: e.genre,
                imageURL: await ArtworkCache.shared.url(for: e.externalID) ?? "",
                kind: ItemKind.music.rawValue,
                countryCode: e.country,          // already known: no lookup needed when the song is chosen
                externalID: e.externalID
            ))
        }
        return items
    }

    // Cover of one curated song or book (used by each row of the list when it appears on screen)
    static func artwork(forCanonID id: String) async -> String {
        if let b = BookCanon.all.first(where: { $0.externalID == id }) { return await canonBookCover(b) }
        guard let e = MusicCanon.all.first(where: { $0.externalID == id }) else { return "" }
        return await canonArtwork(e)
    }

    // Called when the app opens: downloads the first covers and posters in the background
    static func prefetch() async {
        async let movies = essentials(.movies)

        // 1. music covers (found one by one, then remembered)
        let first = Array(MusicCanon.all.prefix(canonPageSize))
        var start = 0
        while start < first.count {
            let chunk = Array(first[start..<min(start + canonParallelSearches, first.count)])
            await withTaskGroup(of: Void.self) { group in
                for e in chunk { group.addTask { _ = await APIService.canonArtwork(e) } }
            }
            start += canonParallelSearches
        }

        // 2. save the pictures themselves on the phone: music covers, book covers, film posters
        var urls: [String] = []
        for e in first {
            if let u = await ArtworkCache.shared.url(for: e.externalID) { urls.append(u) }
        }
        // book covers, 6 at a time
        let firstBooks = Array(BookCanon.all.prefix(bookPageSize))
        var b = 0
        while b < firstBooks.count {
            let chunk = Array(firstBooks[b..<min(b + 6, firstBooks.count)])
            await withTaskGroup(of: Void.self) { group in
                for e in chunk { group.addTask { _ = await APIService.canonBookCover(e) } }
            }
            b += 6
        }
        for e in firstBooks {
            if let u = await ArtworkCache.shared.url(for: e.externalID) { urls.append(u) }
        }
        urls += (await movies).map { $0.imageURL }
        await ImageStore.shared.prefetch(urls)
    }

    // Cover art: ask Apple for the song, keep the first result that really is that song.
    // Tries the main store first (biggest catalogue), then the artist's own country store.
    private static func canonArtwork(_ e: MusicCanon.Entry) async -> String {
        if let known = await ArtworkCache.shared.url(for: e.externalID) { return known }
        let term = "\(coreTitle(e.title)) \(e.artist)"
        for store in [nil, e.country.lowercased()] as [String?] {
            let found = await searchMusic(term, limit: 10, store: store)
            if let best = found.first(where: { sameSong($0, e) }), !best.imageURL.isEmpty {
                await ArtworkCache.shared.set(best.imageURL, for: e.externalID)
                return best.imageURL
            }
        }
        return ""      // no cover found: the song is still listed, with a placeholder picture
    }

    // "Nel blu dipinto di blu (Volare)" -> "Nel blu dipinto di blu"
    private static func coreTitle(_ title: String) -> String {
        title.components(separatedBy: " (").first ?? title
    }

    // Lowercase, no accents, only letters and digits: "Napule è" and "napule e" are the same
    private static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }

    private static func sameSong(_ found: Item, _ e: MusicCanon.Entry) -> Bool {
        let wanted = fold(coreTitle(e.title))
        let title = fold(found.name)
        let titleMatches = title.contains(wanted) || wanted.contains(title)

        // Classical: Apple lists the performers, not the composer, and any performance has a fine cover.
        // The piece is recognised by a distinctive word of its name ("clair", "elise", "toccata"...)
        if e.genre == "Classical" {
            if titleMatches { return true }
            let words = coreTitle(e.title)
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map { fold(String($0)) }
                .filter { $0.count >= 4 }
            return words.contains { title.contains($0) }
        }

        // Everything else: same title and the same artist (any of the names, e.g. "Stan Getz & João Gilberto")
        let artist = fold(found.author)
        let names = e.artist
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { fold(String($0)) }
            .filter { $0.count >= 4 }
        return titleMatches && names.contains { artist.contains($0) }
    }

    // MARK: - Movies: award winners

    private static let moviePageSize = 40          // films shown at a time
    private static let movieParallelSearches = 6   // TMDB searches running together

    // The films come from MovieCanon (country, year and genre are known, so every filter works on them).
    // TMDB is only asked for the poster, the story and the rating.
    private static func canonMovies(_ f: ItemFilter, skipping: Set<String>) async -> [Item] {
        let picks = Array(MovieCanon.matching(f, skipping: skipping).prefix(moviePageSize))
        guard !picks.isEmpty else { return [] }

        var items = [Item?](repeating: nil, count: picks.count)
        await withTaskGroup(of: (Int, Item).self) { group in
            var next = 0
            while next < min(movieParallelSearches, picks.count) {
                let i = next
                group.addTask { (i, await APIService.canonMovieItem(picks[i])) }
                next += 1
            }
            for await (i, item) in group {
                items[i] = item
                if next < picks.count {          // as one search ends, the next one starts
                    let j = next
                    group.addTask { (j, await APIService.canonMovieItem(picks[j])) }
                    next += 1
                }
            }
        }
        return items.compactMap { $0 }
    }

    private static func canonMovieItem(_ e: MovieCanon.Entry) async -> Item {
        if let known = await MovieCache.shared.item(for: e.externalID) { return known }

        // Everything we already know about the film. The award goes where the author normally goes.
        var item = Item(
            name: e.title,
            author: e.awards,
            year: String(e.year),
            details: "",
            kind: ItemKind.movies.rawValue,
            countryCode: e.country,          // already known: no lookup needed when the film is chosen
            externalID: e.externalID
        )

        // TMDB adds poster, story and rating (without a token the film is still listed, with a placeholder)
        if let m = await findMovie(e) {
            let vote = m.vote_average ?? 0
            item.name = m.title
            item.details = m.overview ?? ""
            item.rating = vote > 0 ? String(format: "%.1f/10 (TMDB)", vote) : ""
            item.imageURL = m.poster_path.map { "https://image.tmdb.org/t/p/w500\($0)" } ?? ""
            await MovieCache.shared.set(item, for: e.externalID)
        }
        return item
    }

    // Finds the film on TMDB: released in the same year (±1, festivals and cinemas can differ), same title if possible
    private static func findMovie(_ e: MovieCanon.Entry) async -> TMDBResponse.Movie? {
        guard let d = await tmdbGet("search/movie", ["query": e.title, "include_adult": "false"]),
              let r = try? JSONDecoder().decode(TMDBResponse.self, from: d) else { return nil }

        let wanted = fold(e.title)
        let nearYear = r.results.filter { m in
            guard let y = Int(yearOf(m.release_date)) else { return false }
            return abs(y - e.year) <= 1
        }
        let sameTitle = nearYear.first { m in
            fold(m.title) == wanted || fold(m.original_title ?? "") == wanted
        }
        return sameTitle ?? nearYear.first
    }

    // MARK: - Demos

    // Music: 30-second clip from Apple
    static func musicPreview(for item: Item) async -> String? {
        // song found through search: Apple already gave us its id
        if item.externalID.hasPrefix("itunes-"), let id = Int(item.externalID.dropFirst(7)) {
            guard let d = await get(url("https://itunes.apple.com/lookup", ["id": String(id)])),
                  let r = try? JSONDecoder().decode(ITResponse.self, from: d) else { return nil }
            return r.results.first?.previewUrl
        }
        // curated song: search it and keep the result that really is that song
        guard let e = MusicCanon.all.first(where: { $0.externalID == item.externalID }) else { return nil }
        let term = "\(coreTitle(e.title)) \(e.artist)"
        for store in [nil, e.country.lowercased()] as [String?] {
            var q = ["term": term, "entity": "song", "limit": "10"]
            if let store { q["country"] = store.uppercased() }
            guard let d = await get(url("https://itunes.apple.com/search", q)),
                  let r = try? JSONDecoder().decode(ITResponse.self, from: d) else { continue }
            for t in r.results {
                guard let name = t.trackName, let artist = t.artistName, let p = t.previewUrl else { continue }
                if sameSong(Item(name: name, author: artist), e) { return p }
            }
        }
        return nil
    }

    // Movies: official trailer on YouTube (found through TMDB)
    static func trailer(for item: Item) async -> String? {
        var id: Int?
        if item.externalID.hasPrefix("tmdb-") {
            id = Int(item.externalID.dropFirst(5))
        } else if let e = MovieCanon.all.first(where: { $0.externalID == item.externalID }) {
            id = await findMovie(e)?.id
        }
        guard let id, let d = await tmdbGet("movie/\(id)/videos", [:]),
              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let list = obj["results"] as? [[String: Any]] else { return nil }

        let youtube = list.filter { ($0["site"] as? String) == "YouTube" }
        let trailers = youtube.filter { ($0["type"] as? String) == "Trailer" }
        let pick = trailers.first { ($0["official"] as? Bool) == true } ?? trailers.first ?? youtube.first
        guard let key = pick?["key"] as? String else { return nil }
        return "https://www.youtube.com/watch?v=\(key)"
    }

    // Books: first sentence + short description from Open Library
    static func bookPreview(for item: Item) async -> (first: String, about: String, link: String) {
        var key = ""
        if item.externalID.hasPrefix("ol-/works/") {
            key = String(item.externalID.dropFirst(3))          // "/works/OL123W"
        } else if let e = BookCanon.all.first(where: { $0.externalID == item.externalID }) {
            key = await bookWork(e).key
        }
        guard !key.isEmpty else { return ("", "", "") }

        let link = "https://openlibrary.org\(key)"
        guard let d = await get(URL(string: link + ".json"), timeout: 10),
              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return ("", "", link) }

        func text(_ v: Any?) -> String {
            if let s = v as? String { return s }
            if let o = v as? [String: Any], let s = o["value"] as? String { return s }
            return ""
        }
        let first = text(obj["first_sentence"])
        var about = text(obj["description"])
        if about.count > 450 { about = String(about.prefix(450)) + "…" }
        return (first, about, link)
    }

    // MARK: - Books: curated list

    private static let bookPageSize = 30           // books shown at a time

    // The books come from BookCanon (country, year and genre are known, so every filter works on them).
    // The list appears AT ONCE, with no internet needed. Covers are fetched afterwards, row by row.
    private static func canonBooks(_ f: ItemFilter, skipping: Set<String>) async -> [Item] {
        var items: [Item] = []
        for e in BookCanon.matching(f, skipping: skipping).prefix(bookPageSize) {
            items.append(Item(
                name: e.title,
                author: e.author,
                year: String(e.year),
                details: e.genre,
                imageURL: await ArtworkCache.shared.url(for: e.externalID) ?? "",
                kind: ItemKind.books.rawValue,
                countryCode: e.country,          // already known: no lookup needed when the book is chosen
                externalID: e.externalID
            ))
        }
        return items
    }

    // Finds the book on Open Library: its page and its cover
    private static func bookWork(_ e: BookCanon.Entry) async -> (key: String, cover: String) {
        if let known = await BookWorkCache.shared.work(for: e.externalID) { return known }

        let p = ["q": "\(e.title) \(e.author)", "limit": "5", "fields": "key,title,author_name,cover_i"]
        guard let d = await get(url("https://openlibrary.org/search.json", p), timeout: 10),
              let r = try? JSONDecoder().decode(OLResponse.self, from: d) else { return ("", "") }

        let wanted = fold(e.title)
        let exact = r.docs.first(where: { doc in
            let t = fold(doc.title)
            return doc.cover_i != nil && (t.contains(wanted) || wanted.contains(t))
        })
        let best = exact ?? r.docs.first(where: { $0.cover_i != nil })
        let found = (key: (best?.key ?? r.docs.first?.key) ?? "",
                     cover: best?.cover_i.map { "https://covers.openlibrary.org/b/id/\($0)-M.jpg" } ?? "")
        if !found.key.isEmpty { await BookWorkCache.shared.set(found, for: e.externalID) }
        return found
    }

    private static func canonBookCover(_ e: BookCanon.Entry) async -> String {
        if let known = await ArtworkCache.shared.url(for: e.externalID) { return known }
        let cover = await bookWork(e).cover
        if !cover.isEmpty { await ArtworkCache.shared.set(cover, for: e.externalID) }
        return cover
    }

    // MARK: - Books (Open Library, typed searches)

    private static func olRun(_ q: String, sort: String?, limit: Int, requireCover: Bool) async -> [Item] {
        var p = ["q": q, "limit": String(limit),
                 "fields": "key,title,author_name,first_publish_year,cover_i,ratings_average,subject"]
        if let sort { p["sort"] = sort }
        guard let d = await get(url("https://openlibrary.org/search.json", p), timeout: 10),
              let r = try? JSONDecoder().decode(OLResponse.self, from: d) else { return [] }
        return r.docs.compactMap { doc in
            if requireCover && doc.cover_i == nil { return nil }
            let rating = (doc.ratings_average ?? 0) > 0
                ? String(format: "%.1f/5 (Open Library)", doc.ratings_average ?? 0) : ""
            return Item(
                name: doc.title,
                author: doc.author_name?.first ?? "",
                year: doc.first_publish_year.map(String.init) ?? "",
                details: (doc.subject ?? []).prefix(4).joined(separator: " • "),
                rating: rating,
                imageURL: doc.cover_i.map { "https://covers.openlibrary.org/b/id/\($0)-M.jpg" } ?? "",
                kind: ItemKind.books.rawValue,
                externalID: "ol-\(doc.key ?? doc.title)"
            )
        }
    }

    private static func olSearch(_ q: String, sort: String?, limit: Int, requireCover: Bool) async -> [Item] {
        guard sort != nil else { return await olRun(q, sort: nil, limit: limit, requireCover: requireCover) }
        async let sorted = olRun(q, sort: sort, limit: limit, requireCover: requireCover)
        async let plain = olRun(q, sort: nil, limit: limit, requireCover: requireCover)
        let first = await sorted
        return first.isEmpty ? await plain : first
    }
}
