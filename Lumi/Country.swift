
import Foundation

struct Country: Identifiable {
    let id = UUID()
    var name: String
    var flag: String
    var categories: [Category]
}

extension Country {
    // ISO codes used by MapBOX for the enabled countries in this prototype
    private static let isoByName = ["France": "FRA", "Germany": "DEU", "Italy": "ITA"]

    var isoCode: String? { Country.isoByName[name] }

    // Implemented countries
    static var implementedISOCodes: Set<String> {
        Set(infoData.countries.compactMap { $0.isoCode })
    }
}
