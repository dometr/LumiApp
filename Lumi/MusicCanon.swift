import Foundation

// Songs picked for their CULTURAL VALUE (landmark recordings), not for how many people play them.
//
// temporary list curated by hand until we found a way to sort the api based on cultural value, api is still used to lookup

// One song per line:  Title | Artist | country of the artist (ISO alpha-2) | year | genre
//  - genre must be one of the music genres of the filter screen, or empty for traditions the filter
//    has no label for (fado, flamenco, afrobeat...): those songs show up when no genre is selected.
//  - the order inside a country is its importance: the first song of each country is shown first.
// To add a song, add a line. To remove one, delete its line.
nonisolated enum MusicCanon {

    nonisolated struct Entry: Sendable {
        let title: String
        let artist: String
        let country: String
        let year: Int
        let genre: String

        // Stable id, so a song that was completed is not suggested again
        var externalID: String {
            "canon-" + (title + artist).lowercased().filter { $0.isLetter || $0.isNumber }
        }
    }

    // The whole list, mixed so that neighbours come from different countries:
    // round 1 = the top song of every country, round 2 = the second of every country...
    static let all: [Entry] = {
        let list: [Entry] = raw.split(separator: "\n").compactMap { line in
            let part = line.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard part.count == 5, let year = Int(part[3]) else { return nil }
            return Entry(title: part[0], artist: part[1], country: part[2], year: year, genre: part[4])
        }
        return interleaved(list)
    }()

    // What matches the filter, minus the songs already completed
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
                if let songs = byCountry[c], round < songs.count { result.append(songs[round]) }
            }
            round += 1
        }
        return result
    }

    private static let raw = """
        Nel blu dipinto di blu (Volare) | Domenico Modugno | IT | 1958 | Pop
        Il cielo in una stanza | Mina | IT | 1960 | Pop
        La cura | Franco Battiato | IT | 1996 | Pop
        Bocca di rosa | Fabrizio De André | IT | 1967 | Folk
        Napule è | Pino Daniele | IT | 1977 | Blues
        Azzurro | Adriano Celentano | IT | 1968 | Pop
        Albachiara | Vasco Rossi | IT | 1979 | Rock
        Caruso | Lucio Dalla | IT | 1986 | Pop
        Impressioni di settembre | Premiata Forneria Marconi | IT | 1971 | Rock
        Generale | Francesco De Gregori | IT | 1978 | Folk
        Nessun dorma | Luciano Pavarotti | IT | 1972 | Classical
        Spring (The Four Seasons) | Antonio Vivaldi | IT | 1725 | Classical
        La Vie en rose | Édith Piaf | FR | 1947 | Pop
        Non, je ne regrette rien | Édith Piaf | FR | 1960 | Pop
        Je t'aime... moi non plus | Serge Gainsbourg & Jane Birkin | FR | 1969 | Pop
        La Bohème | Charles Aznavour | FR | 1965 | Pop
        La Mer | Charles Trenet | FR | 1946 | Pop
        Les Feuilles mortes | Yves Montand | FR | 1949 | Pop
        Clair de lune | Claude Debussy | FR | 1905 | Classical
        Gymnopédie No. 1 | Erik Satie | FR | 1888 | Classical
        Boléro | Maurice Ravel | FR | 1928 | Classical
        Around the World | Daft Punk | FR | 1997 | Electronic
        Aux Champs-Élysées | Joe Dassin | FR | 1969 | Pop
        La Javanaise | Serge Gainsbourg | FR | 1963 | Pop
        Für Elise | Ludwig van Beethoven | DE | 1810 | Classical
        Ode to Joy (Symphony No. 9) | Ludwig van Beethoven | DE | 1824 | Classical
        Toccata and Fugue in D Minor | Johann Sebastian Bach | DE | 1708 | Classical
        Autobahn | Kraftwerk | DE | 1974 | Electronic
        99 Luftballons | Nena | DE | 1983 | Pop
        Trans-Europe Express | Kraftwerk | DE | 1977 | Electronic
        Du hast | Rammstein | DE | 1997 | Rock
        Lili Marleen | Lale Andersen | DE | 1939 | Pop
        Wind of Change | Scorpions | DE | 1990 | Rock
        Air on the G String | Johann Sebastian Bach | DE | 1730 | Classical
        Major Tom (Völlig losgelöst) | Peter Schilling | DE | 1982 | Pop
        A Day in the Life | The Beatles | GB | 1967 | Rock
        Bohemian Rhapsody | Queen | GB | 1975 | Rock
        Space Oddity | David Bowie | GB | 1969 | Rock
        Paranoid Android | Radiohead | GB | 1997 | Alternative
        London Calling | The Clash | GB | 1979 | Rock
        Love Will Tear Us Apart | Joy Division | GB | 1980 | Alternative
        Wuthering Heights | Kate Bush | GB | 1978 | Pop
        Blue Monday | New Order | GB | 1983 | Electronic
        Stairway to Heaven | Led Zeppelin | GB | 1971 | Rock
        Anarchy in the U.K. | Sex Pistols | GB | 1976 | Rock
        Like a Rolling Stone | Bob Dylan | US | 1965 | Rock
        What's Going On | Marvin Gaye | US | 1971 | R&B/Soul
        Strange Fruit | Billie Holiday | US | 1939 | Jazz
        Take Five | The Dave Brubeck Quartet | US | 1959 | Jazz
        Respect | Aretha Franklin | US | 1967 | R&B/Soul
        A Change Is Gonna Come | Sam Cooke | US | 1964 | R&B/Soul
        Blowin' in the Wind | Bob Dylan | US | 1963 | Folk
        Cross Road Blues | Robert Johnson | US | 1937 | Blues
        Johnny B. Goode | Chuck Berry | US | 1958 | Rock
        So What | Miles Davis | US | 1959 | Jazz
        The Message | Grandmaster Flash & The Furious Five | US | 1982 | Hip-Hop/Rap
        Fight the Power | Public Enemy | US | 1989 | Hip-Hop/Rap
        I Walk the Line | Johnny Cash | US | 1956 | Country
        Rhapsody in Blue | George Gershwin | US | 1924 | Classical
        I Feel Love | Donna Summer | US | 1977 | Dance
        Smells Like Teen Spirit | Nirvana | US | 1991 | Alternative
        This Land Is Your Land | Woody Guthrie | US | 1944 | Folk
        Purple Rain | Prince | US | 1984 | R&B/Soul
        Mississippi Goddam | Nina Simone | US | 1964 | Jazz
        Jolene | Dolly Parton | US | 1973 | Country
        Juicy | The Notorious B.I.G. | US | 1994 | Hip-Hop/Rap
        The Girl from Ipanema | Stan Getz & João Gilberto | BR | 1964 | Latin
        Águas de Março | Elis Regina & Antonio Carlos Jobim | BR | 1974 | Latin
        Construção | Chico Buarque | BR | 1971 | Latin
        Alegria, Alegria | Caetano Veloso | BR | 1967 | Latin
        Asa Branca | Luiz Gonzaga | BR | 1947 | Latin
        Redemption Song | Bob Marley & The Wailers | JM | 1980 | Reggae
        One Love / People Get Ready | Bob Marley & The Wailers | JM | 1977 | Reggae
        Many Rivers to Cross | Jimmy Cliff | JM | 1969 | Reggae
        Libertango | Astor Piazzolla | AR | 1974 | Latin
        Alfonsina y el mar | Mercedes Sosa | AR | 1969 | Folk
        Por una cabeza | Carlos Gardel | AR | 1935 | Latin
        Entre dos aguas | Paco de Lucía | ES | 1973 |
        Mediterráneo | Joan Manuel Serrat | ES | 1971 | Folk
        Concierto de Aranjuez | Joaquín Rodrigo | ES | 1939 | Classical
        Sukiyaki | Kyu Sakamoto | JP | 1961 | Pop
        Rydeen | Yellow Magic Orchestra | JP | 1979 | Electronic
        Merry Christmas, Mr. Lawrence | Ryuichi Sakamoto | JP | 1983 |
        Swan Lake | Pyotr Ilyich Tchaikovsky | RU | 1877 | Classical
        The Rite of Spring | Igor Stravinsky | RU | 1913 | Classical
        Dance of the Knights | Sergei Prokofiev | RU | 1935 | Classical
        Eine kleine Nachtmusik | Wolfgang Amadeus Mozart | AT | 1787 | Classical
        The Blue Danube | Johann Strauss II | AT | 1866 | Classical
        Rock Me Amadeus | Falco | AT | 1985 | Pop
        Hallelujah | Leonard Cohen | CA | 1984 | Folk
        Both Sides, Now | Joni Mitchell | CA | 1969 | Folk
        Nothing Compares 2 U | Sinéad O'Connor | IE | 1990 | Pop
        Sunday Bloody Sunday | U2 | IE | 1983 | Rock
        Ne me quitte pas | Jacques Brel | BE | 1959 | Pop
        Alors on danse | Stromae | BE | 2009 | Dance
        Chan Chan | Buena Vista Social Club | CU | 1997 | Latin
        La Llorona | Chavela Vargas | MX | 1961 | Latin
        En Barranquilla se baila así | Joe Arroyo | CO | 1986 | Latin
        Gracias a la vida | Violeta Parra | CL | 1966 | Folk
        El derecho de vivir en paz | Víctor Jara | CL | 1971 | Folk
        Estranha Forma de Vida | Amália Rodrigues | PT | 1962 |
        Sodade | Cesária Évora | CV | 1992 |
        Water No Get Enemy | Fela Kuti | NG | 1975 |
        Grazing in the Grass | Hugh Masekela | ZA | 1968 | Jazz
        Pata Pata | Miriam Makeba | ZA | 1967 |
        7 Seconds | Youssou N'Dour & Neneh Cherry | SN | 1994 | Pop
        Yé ké yé ké | Mory Kanté | GN | 1987 | Dance
        Enta Omri | Umm Kulthum | EG | 1965 |
        Lag Jaa Gale | Lata Mangeshkar | IN | 1964 |
        Zorba's Dance | Mikis Theodorakis | GR | 1964 | Folk
        In the Hall of the Mountain King | Edvard Grieg | NO | 1875 | Classical
        Dancing Queen | ABBA | SE | 1976 | Pop
        Hyperballad | Björk | IS | 1995 | Electronic
        Finlandia | Jean Sibelius | FI | 1900 | Classical
        Nocturne Op. 9 No. 2 | Frédéric Chopin | PL | 1832 | Classical
        Vltava | Bedřich Smetana | CZ | 1874 | Classical
        Hungarian Rhapsody No. 2 | Franz Liszt | HU | 1847 | Classical
        Treaty | Yothu Yindi | AU | 1991 | Alternative
        """
}
