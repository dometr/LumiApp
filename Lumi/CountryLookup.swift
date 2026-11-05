import Foundation

// Finds the country of a book (its author) or a song (its artist) automatically
nonisolated enum CountryLookup {

    static func country(for item: Item) async -> String? {
        switch item.kind {
        case ItemKind.books.rawValue: return await bookCountry(item)
        case ItemKind.music.rawValue: return await musicCountry(item)
        default: return nil
        }
    }

    // MARK: - Music (MusicBrainz, no key)

    private static func musicCountry(_ item: Item) async -> String? {
        for name in artistNames(item.author) {
            guard let json = await getJSON("https://musicbrainz.org/ws/2/artist/",
                                           ["query": "artist:\"\(name)\"", "fmt": "json", "limit": "5"]),
                  let artists = json["artists"] as? [[String: Any]] else { continue }
            for a in artists {
                let score = a["score"] as? Int ?? 0
                if score >= 90, let code = valid(a["country"] as? String) { return code }
            }
        }
        return nil
    }

    // "Serge Gainsbourg & Jane Birkin" -> the first two names
    private static func artistNames(_ s: String) -> [String] {
        var t = s
        for sep in [" feat. ", " feat ", " ft. ", " & ", " / ", " x ", ", ", " with ", " and "] {
            t = t.replacingOccurrences(of: sep, with: "|", options: .caseInsensitive)
        }
        return t.split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: " ") }
            .filter { !$0.isEmpty }
            .prefix(2)
            .map { $0 }
    }

    // MARK: - Books (Open Library + Wikidata, no key)

    private static func bookCountry(_ item: Item) async -> String? {
        // 1) Open Library: work -> author -> Wikidata id
        if item.externalID.hasPrefix("ol-/works/"),
           let qid = await authorQID(workPath: String(item.externalID.dropFirst(3))),
           let c = await countryOfPerson(qid) {
            return c
        }
        // 2) otherwise search the author's name on Wikidata
        return await countryByName(item.author)
    }

    private static func authorQID(workPath: String) async -> String? {
        guard let work = await getJSON("https://openlibrary.org\(workPath).json", [:]),
              let first = (work["authors"] as? [[String: Any]])?.first,
              let key = (first["author"] as? [String: Any])?["key"] as? String,
              let author = await getJSON("https://openlibrary.org\(key).json", [:]),
              let remote = author["remote_ids"] as? [String: Any],
              let qid = remote["wikidata"] as? String else { return nil }
        return qid
    }

    private static func countryByName(_ name: String) async -> String? {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty,
              let s = await getJSON("https://www.wikidata.org/w/api.php",
                                    ["action": "wbsearchentities", "search": n, "language": "en",
                                     "type": "item", "limit": "5", "format": "json"]),
              let hits = s["search"] as? [[String: Any]] else { return nil }
        let found = hits.compactMap { $0["id"] as? String }
        guard !found.isEmpty, let all = await entities(found) else { return nil }
        for id in found {   // keep Wikidata's ranking, humans only (Q5)
            guard let claims = (all[id] as? [String: Any])?["claims"] as? [String: Any],
                  claimIDs(claims, "P31").contains("Q5") else { continue }
            if let c = await countryOfClaims(claims) { return c }
        }
        return nil
    }

    // MARK: - Wikidata helpers

    private static func entities(_ ids: [String]) async -> [String: Any]? {
        let r = await getJSON("https://www.wikidata.org/w/api.php",
                              ["action": "wbgetentities", "ids": ids.joined(separator: "|"),
                               "props": "claims", "format": "json"])
        return r?["entities"] as? [String: Any]
    }

    // all the item ids a property points to, e.g. P27 -> ["Q142"]
    private static func claimIDs(_ claims: [String: Any], _ prop: String) -> [String] {
        ((claims[prop] as? [[String: Any]]) ?? []).compactMap { c in
            let snak = c["mainsnak"] as? [String: Any]
            let value = (snak?["datavalue"] as? [String: Any])?["value"] as? [String: Any]
            return value?["id"] as? String
        }
    }

    private static func countryOfPerson(_ qid: String) async -> String? {
        guard let e = await entities([qid]),
              let claims = (e[qid] as? [String: Any])?["claims"] as? [String: Any] else { return nil }
        return await countryOfClaims(claims)
    }

    // citizenship (P27), otherwise the country of the birthplace (P19 -> P17)
    private static func countryOfClaims(_ claims: [String: Any]) async -> String? {
        if let c = await isoCode(ofCountries: claimIDs(claims, "P27")) { return c }
        let places = claimIDs(claims, "P19")
        guard !places.isEmpty, let pe = await entities(places) else { return nil }
        var countries: [String] = []
        for p in places {
            if let pc = (pe[p] as? [String: Any])?["claims"] as? [String: Any] {
                countries += claimIDs(pc, "P17")
            }
        }
        return await isoCode(ofCountries: countries)
    }

    // ISO alpha-2 code (P297) of the first country that has a current one
    private static func isoCode(ofCountries ids: [String]) async -> String? {
        guard !ids.isEmpty, let e = await entities(Array(ids.prefix(10))) else { return nil }
        for id in ids {
            guard let claims = (e[id] as? [String: Any])?["claims"] as? [String: Any] else { continue }
            let codes = ((claims["P297"] as? [[String: Any]]) ?? []).compactMap { c -> String? in
                ((c["mainsnak"] as? [String: Any])?["datavalue"] as? [String: Any])?["value"] as? String
            }
            if let code = codes.compactMap({ valid($0) }).first { return code }
        }
        return nil
    }

    // MARK: - Shared

    private static let regions: Set<String> = Set(Locale.Region.isoRegions.map { $0.identifier })

    // only real, current ISO codes (drops codes like "XW" = worldwide)
    private static func valid(_ c: String?) -> String? {
        guard let c = c?.uppercased(), c.count == 2, regions.contains(c) else { return nil }
        return c
    }

    private static func getJSON(_ base: String, _ query: [String: String]) async -> [String: Any]? {
        var comps = URLComponents(string: base)
        if !query.isEmpty { comps?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) } }
        guard let url = comps?.url else { return nil }
        var r = URLRequest(url: url)
        r.timeoutInterval = 8
        r.setValue("LumiApp/1.0 (student project)", forHTTPHeaderField: "User-Agent")
        guard let (d, resp) = try? await URLSession.shared.data(for: r),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return (try? JSONSerialization.jsonObject(with: d)) as? [String: Any]
    }
}
