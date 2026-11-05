import Foundation

// Books picked for their CULTURAL VALUE (classics that shaped a country's literature).
//
// temporary list curated by hand until we find a way to sort the api based on cultural value , openlibrary is used to lookup description and photos
//
// One book per line:  Title | Author | country of the author (ISO alpha-2) | first published | genre
//  - genre must be one of the book genres of the filter screen (Fiction, Fantasy, Science Fiction,
//    Mystery, Romance, Thriller, Horror, History, Biography, Poetry, Philosophy, Classics)
//  - the order inside a country is its importance: the first book of each country is shown first.
// To add a book, add a line. To remove one, delete its line.
nonisolated enum BookCanon {

    nonisolated struct Entry: Sendable {
        let title: String
        let author: String
        let country: String
        let year: Int
        let genre: String

        // Stable id, so a book that was completed is not suggested again
        var externalID: String {
            "canon-book-" + (title + author).lowercased().filter { $0.isLetter || $0.isNumber }
        }
    }

    // The whole list, mixed so that neighbours come from different countries
    static let all: [Entry] = {
        let list: [Entry] = raw.split(separator: "\n").compactMap { line in
            let part = line.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard part.count == 5, let year = Int(part[3]) else { return nil }
            return Entry(title: part[0], author: part[1], country: part[2], year: year, genre: part[4])
        }
        return interleaved(list)
    }()

    // What matches the filter, minus the books already completed
    static func matching(_ f: ItemFilter, skipping done: Set<String>) -> [Entry] {
        all.filter { e in
            if done.contains(e.externalID) { return false }
            if let g = f.genre, e.genre != g { return false }
            if let c = f.country, e.country != c { return false }
            if f.hasYears, e.year < (f.yearFrom ?? 0) || e.year > (f.yearTo ?? 9999) { return false }
            return true
        }
    }

    private static func interleaved(_ list: [Entry]) -> [Entry] {
        var order: [String] = []                       // countries, in order of first appearance
        var byCountry: [String: [Entry]] = [:]
        for e in list {
            if byCountry[e.country] == nil { order.append(e.country) }
            byCountry[e.country, default: []].append(e)
        }
        var result: [Entry] = []
        var round = 0
        while result.count < list.count {
            for c in order {
                if let books = byCountry[c], round < books.count { result.append(books[round]) }
            }
            round += 1
        }
        return result
    }

    private static let raw = """
        The Divine Comedy | Dante Alighieri | IT | 1320 | Poetry
        The Name of the Rose | Umberto Eco | IT | 1980 | Mystery
        If This Is a Man | Primo Levi | IT | 1947 | History
        The Leopard | Giuseppe Tomasi di Lampedusa | IT | 1958 | Fiction
        Invisible Cities | Italo Calvino | IT | 1972 | Fiction
        The Betrothed | Alessandro Manzoni | IT | 1827 | Classics
        The Adventures of Pinocchio | Carlo Collodi | IT | 1883 | Fantasy
        The Prince | Niccolò Machiavelli | IT | 1532 | Philosophy
        My Brilliant Friend | Elena Ferrante | IT | 2011 | Fiction
        The Decameron | Giovanni Boccaccio | IT | 1353 | Classics
        The Little Prince | Antoine de Saint-Exupéry | FR | 1943 | Fantasy
        Les Misérables | Victor Hugo | FR | 1862 | Classics
        The Stranger | Albert Camus | FR | 1942 | Fiction
        The Count of Monte Cristo | Alexandre Dumas | FR | 1844 | Classics
        Madame Bovary | Gustave Flaubert | FR | 1857 | Classics
        Twenty Thousand Leagues Under the Seas | Jules Verne | FR | 1870 | Science Fiction
        Swann's Way | Marcel Proust | FR | 1913 | Classics
        The Phantom of the Opera | Gaston Leroux | FR | 1910 | Mystery
        The Second Sex | Simone de Beauvoir | FR | 1949 | Philosophy
        Candide | Voltaire | FR | 1759 | Philosophy
        Faust | Johann Wolfgang von Goethe | DE | 1808 | Classics
        The Metamorphosis | Franz Kafka | DE | 1915 | Fiction
        The Trial | Franz Kafka | DE | 1925 | Fiction
        All Quiet on the Western Front | Erich Maria Remarque | DE | 1929 | Fiction
        Siddhartha | Hermann Hesse | DE | 1922 | Philosophy
        Steppenwolf | Hermann Hesse | DE | 1927 | Fiction
        The Magic Mountain | Thomas Mann | DE | 1924 | Classics
        The Tin Drum | Günter Grass | DE | 1959 | Fiction
        Perfume | Patrick Süskind | DE | 1985 | Thriller
        The Sorrows of Young Werther | Johann Wolfgang von Goethe | DE | 1774 | Romance
        Grimms' Fairy Tales | Brothers Grimm | DE | 1812 | Fantasy
        Don Quixote | Miguel de Cervantes | ES | 1605 | Classics
        One Hundred Years of Solitude | Gabriel García Márquez | CO | 1967 | Fiction
        Pride and Prejudice | Jane Austen | GB | 1813 | Romance
        1984 | George Orwell | GB | 1949 | Science Fiction
        The Hobbit | J. R. R. Tolkien | GB | 1937 | Fantasy
        Frankenstein | Mary Shelley | GB | 1818 | Horror
        Murder on the Orient Express | Agatha Christie | GB | 1934 | Mystery
        Alice's Adventures in Wonderland | Lewis Carroll | GB | 1865 | Fantasy
        Crime and Punishment | Fyodor Dostoevsky | RU | 1866 | Classics
        War and Peace | Leo Tolstoy | RU | 1869 | Classics
        The Great Gatsby | F. Scott Fitzgerald | US | 1925 | Classics
        To Kill a Mockingbird | Harper Lee | US | 1960 | Fiction
        Dune | Frank Herbert | US | 1965 | Science Fiction
        Dracula | Bram Stoker | IE | 1897 | Horror
        The Tale of Genji | Murasaki Shikibu | JP | 1010 | Classics
        Norwegian Wood | Haruki Murakami | JP | 1987 | Romance
        Things Fall Apart | Chinua Achebe | NG | 1958 | Fiction
        The Alchemist | Paulo Coelho | BR | 1988 | Fiction
        """
}
