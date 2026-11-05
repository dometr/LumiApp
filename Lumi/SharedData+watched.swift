import Foundation

extension SharedData {
    // id changes every launch other fields do not 
    func item(photo: String, name: String) -> Item? {
        for country in countries {
            for category in country.categories {
                if let found = category.items.first(where: { $0.photo == photo && $0.name == name }) {
                    return found
                }
            }
        }
        return nil
    }

    //marks watched based on id
    func markWatched(_ itemID: UUID) {
        for country in countries.indices {
            for category in countries[country].categories.indices {
                for item in countries[country].categories[category].items.indices {
                    if countries[country].categories[category].items[item].id == itemID {
                        countries[country].categories[category].items[item].watched = true
                    }
                }
            }
        }
    }
}
