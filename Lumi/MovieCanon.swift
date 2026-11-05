import Foundation

// Films picked for their AWARDS (Oscars, Cannes, Venice, Berlin, BAFTA...), not for how popular they are.
//
// temporary list curated by hand because apis dont store data regarding awards , tmdb is used to lookup
//
// One film per line:  Title | awards | country of production (ISO alpha-2) | year | genre
//  - Title is the English title (TMDB finds the film from it).
//  - genre must be one of the movie genres of the filter screen.
//  - the order inside a country is its importance: the first film of each country is shown first.
// To add a film, add a line. To remove one, delete its line.
nonisolated enum MovieCanon {

    nonisolated struct Entry: Sendable {
        let title: String
        let awards: String
        let country: String
        let year: Int
        let genre: String

        // Stable id, so a film that was completed is not suggested again
        var externalID: String {
            "canon-film-" + (title + String(year)).lowercased().filter { $0.isLetter || $0.isNumber }
        }
    }

    // The whole list, mixed so that neighbours come from different countries:
    // round 1 = the top film of every country, round 2 = the second of every country...
    static let all: [Entry] = {
        let list: [Entry] = raw.split(separator: "\n").compactMap { line in
            let part = line.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard part.count == 5, let year = Int(part[3]) else { return nil }
            return Entry(title: part[0], awards: part[1], country: part[2], year: year, genre: part[4])
        }
        return interleaved(list)
    }()

    // What matches the filter, minus the films already completed
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
                if let films = byCountry[c], round < films.count { result.append(films[round]) }
            }
            round += 1
        }
        return result
    }

    private static let raw = """
        Life Is Beautiful | 3 Oscars incl. Best International Feature | IT | 1997 | Comedy
        Anatomy of a Fall | Palme d'Or; Oscar: Best Original Screenplay | FR | 2023 | Mystery
        Casablanca | Oscar: Best Picture | US | 1942 | Romance
        Lawrence of Arabia | Oscar: Best Picture | GB | 1962 | History
        The Tin Drum | Palme d'Or; Oscar: Best International Feature | DE | 1979 | War
        Rashomon | Golden Lion; Honorary Oscar | JP | 1950 | Crime
        Parasite | Palme d'Or; Oscar: Best Picture | KR | 2019 | Thriller
        A Separation | Golden Bear; Oscar: Best International Feature | IR | 2011 | Drama
        The Sea Inside | Oscar: Best International Feature | ES | 2004 | Drama
        Roma | Golden Lion; Oscar: Best Director | MX | 2018 | Drama
        The Official Story | Oscar: Best International Feature | AR | 1985 | Drama
        Black Orpheus | Palme d'Or; Oscar: Best Foreign Language Film | BR | 1959 | Romance
        A Fantastic Woman | Oscar: Best International Feature | CL | 2017 | Drama
        War and Peace | Oscar: Best Foreign Language Film | RU | 1966 | War
        The Pianist | Palme d'Or; Oscar: Best Director | PL | 2002 | War
        The Shop on Main Street | Oscar: Best Foreign Language Film | CZ | 1965 | Drama
        Mephisto | Oscar: Best Foreign Language Film | HU | 1981 | Drama
        Amour | Palme d'Or; Oscar: Best International Feature | AT | 2012 | Drama
        Babette's Feast | Oscar: Best Foreign Language Film | DK | 1987 | Drama
        Fanny and Alexander | Oscar: Best Foreign Language Film | SE | 1982 | Drama
        The Man Without a Past | Cannes Grand Prix | FI | 2002 | Comedy
        Character | Oscar: Best Foreign Language Film | NL | 1997 | Drama
        Rosetta | Palme d'Or | BE | 1999 | Drama
        Zorba the Greek | 3 Oscars | GR | 1964 | Drama
        Winter Sleep | Palme d'Or | TR | 2014 | Drama
        4 Months, 3 Weeks and 2 Days | Palme d'Or | RO | 2007 | Drama
        Underground | Palme d'Or | RS | 1995 | War
        No Man's Land | Oscar: Best Foreign Language Film | BA | 2001 | War
        20 Days in Mariupol | Oscar: Best Documentary Feature | UA | 2023 | Documentary
        Flow | Oscar: Best Animated Feature | LV | 2024 | Animation
        Waltz with Bashir | Golden Globe: Best Foreign Language Film | IL | 2008 | Animation
        Pather Panchali | Cannes: Best Human Document | IN | 1955 | Drama
        Farewell My Concubine | Palme d'Or | CN | 1993 | Drama
        Crouching Tiger, Hidden Dragon | Oscar: Best Foreign Language Film | TW | 2000 | Action
        In the Mood for Love | Cannes: Best Actor | HK | 2000 | Romance
        Uncle Boonmee Who Can Recall His Past Lives | Palme d'Or | TH | 2010 | Fantasy
        Mad Max: Fury Road | 6 Oscars | AU | 2015 | Action
        The Piano | Palme d'Or; 3 Oscars | NZ | 1993 | Romance
        The Barbarian Invasions | Oscar: Best Foreign Language Film | CA | 2003 | Comedy
        The Wind That Shakes the Barley | Palme d'Or | IE | 2006 | War
        Z | Oscar: Best Foreign Language Film | DZ | 1969 | Thriller
        Atlantics | Cannes Grand Prix | SN | 2019 | Romance
        Tsotsi | Oscar: Best Foreign Language Film | ZA | 2005 | Crime
        The Great Beauty | Oscar: Best International Feature; BAFTA; Golden Globe | IT | 2013 | Drama
        The Artist | Oscar: Best Picture | FR | 2011 | Romance
        The Godfather | Oscar: Best Picture | US | 1972 | Crime
        Gandhi | Oscar: Best Picture | GB | 1982 | History
        The Lives of Others | Oscar: Best International Feature | DE | 2006 | Thriller
        Departures | Oscar: Best International Feature | JP | 2008 | Drama
        Oldboy | Cannes Grand Prix | KR | 2003 | Thriller
        The Salesman | Oscar: Best International Feature | IR | 2016 | Drama
        All About My Mother | Oscar: Best International Feature | ES | 1999 | Drama
        The Forgotten Ones | Cannes: Best Director | MX | 1950 | Crime
        The Secret in Their Eyes | Oscar: Best International Feature | AR | 2009 | Mystery
        The Given Word | Palme d'Or | BR | 1962 | Drama
        The Cranes Are Flying | Palme d'Or | RU | 1957 | War
        Ida | Oscar: Best International Feature | PL | 2013 | Drama
        Closely Watched Trains | Oscar: Best Foreign Language Film | CZ | 1966 | Comedy
        Son of Saul | Oscar: Best Foreign Language Film | HU | 2015 | War
        The Counterfeiters | Oscar: Best Foreign Language Film | AT | 2007 | War
        Pelle the Conqueror | Palme d'Or; Oscar: Best Foreign Language Film | DK | 1987 | Drama
        The Virgin Spring | Oscar: Best Foreign Language Film | SE | 1960 | Drama
        Compartment No. 6 | Cannes Grand Prix | FI | 2021 | Drama
        Antonia's Line | Oscar: Best Foreign Language Film | NL | 1995 | Drama
        The Child | Palme d'Or | BE | 2005 | Crime
        Yol | Palme d'Or | TR | 1982 | Drama
        When Father Was Away on Business | Palme d'Or | BA | 1985 | Drama
        Aparajito | Golden Lion | IN | 1956 | Drama
        Red Sorghum | Golden Bear | CN | 1987 | Drama
        A City of Sadness | Golden Lion | TW | 1989 | History
        Shine | Oscar: Best Actor | AU | 1996 | Drama
        The Sweet Hereafter | Cannes Grand Prix | CA | 1997 | Drama
        Once | Oscar: Best Original Song | IE | 2007 | Romance
        Chronicle of the Years of Fire | Palme d'Or | DZ | 1975 | War
        My Octopus Teacher | Oscar: Best Documentary Feature | ZA | 2020 | Documentary
        8½ | Oscar: Best International Feature; Costume Design | IT | 1963 | Drama
        The Umbrellas of Cherbourg | Palme d'Or | FR | 1964 | Romance
        The Godfather Part II | Oscar: Best Picture | US | 1974 | Crime
        The Bridge on the River Kwai | Oscar: Best Picture | GB | 1957 | War
        Paris, Texas | Palme d'Or | DE | 1984 | Drama
        Drive My Car | Oscar: Best International Feature | JP | 2021 | Drama
        Decision to Leave | Cannes: Best Director | KR | 2022 | Mystery
        Taste of Cherry | Palme d'Or | IR | 1997 | Drama
        Talk to Her | Oscar: Best Original Screenplay | ES | 2002 | Romance
        Argentina, 1985 | Golden Globe: Best Non-English Language Film | AR | 2022 | History
        Central Station | Golden Bear | BR | 1998 | Drama
        Moscow Does Not Believe in Tears | Oscar: Best Foreign Language Film | RU | 1980 | Romance
        Man of Iron | Palme d'Or | PL | 1981 | Drama
        Kolya | Oscar: Best Foreign Language Film | CZ | 1996 | Comedy
        Dancer in the Dark | Palme d'Or | DK | 2000 | Drama
        Through a Glass Darkly | Oscar: Best Foreign Language Film | SE | 1961 | Drama
        Honey | Golden Bear | TR | 2010 | Drama
        Monsoon Wedding | Golden Lion | IN | 2001 | Comedy
        Vive L'Amour | Golden Lion | TW | 1994 | Drama
        The Banshees of Inisherin | Golden Globe: Best Comedy | IE | 2022 | Comedy
        La Dolce Vita | Palme d'Or; Oscar: Costume Design | IT | 1960 | Drama
        A Man and a Woman | Palme d'Or; Oscar: Best Foreign Language Film | FR | 1966 | Romance
        Schindler's List | Oscar: Best Picture | US | 1993 | History
        Slumdog Millionaire | Oscar: Best Picture | GB | 2008 | Drama
        All Quiet on the Western Front | Oscar: Best International Feature; BAFTA: Best Film | DE | 2022 | War
        Gate of Hell | Palme d'Or; Honorary Oscar | JP | 1953 | History
        Pietà | Golden Lion | KR | 2012 | Drama
        There Is No Evil | Golden Bear | IR | 2020 | Drama
        Belle Epoque | Oscar: Best Foreign Language Film | ES | 1992 | Comedy
        The Circle | Golden Lion | IR | 2000 | Drama
        Cinema Paradiso | Oscar: Best International Feature; Cannes Grand Prix | IT | 1988 | Drama
        Blue Is the Warmest Colour | Palme d'Or | FR | 2013 | Romance
        One Flew Over the Cuckoo's Nest | Oscar: Best Picture | US | 1975 | Drama
        Chariots of Fire | Oscar: Best Picture | GB | 1981 | Drama
        The White Ribbon | Palme d'Or | DE | 2009 | Drama
        Kagemusha | Palme d'Or | JP | 1980 | War
        Taxi | Golden Bear | IR | 2015 | Comedy
        Pan's Labyrinth | 3 Oscars | ES | 2006 | Fantasy
        Dersu Uzala | Oscar: Best Foreign Language Film | RU | 1975 | Adventure
        In a Better World | Oscar: Best Foreign Language Film | DK | 2010 | Drama
        Triangle of Sadness | Palme d'Or | SE | 2022 | Comedy
        Neecha Nagar | Cannes Grand Prix | IN | 1946 | Drama
        La Strada | Oscar: Best International Feature | IT | 1954 | Drama
        Titane | Palme d'Or | FR | 2021 | Horror
        Forrest Gump | Oscar: Best Picture | US | 1994 | Drama
        The King's Speech | Oscar: Best Picture | GB | 2010 | History
        Head-On | Golden Bear | DE | 2004 | Drama
        Shoplifters | Palme d'Or | JP | 2018 | Crime
        It Was Just an Accident | Palme d'Or | IR | 2025 | Drama
        Viridiana | Palme d'Or | ES | 1961 | Drama
        Another Round | Oscar: Best International Feature | DK | 2020 | Comedy
        The Best Intentions | Palme d'Or | SE | 1992 | Drama
        RRR | Oscar: Best Original Song | IN | 2022 | Action
        The Leopard | Palme d'Or | IT | 1963 | History
        The 400 Blows | Cannes: Best Director | FR | 1959 | Drama
        Titanic | Oscar: Best Picture | US | 1997 | Romance
        Tom Jones | Oscar: Best Picture | GB | 1963 | Comedy
        Toni Erdmann | European Film Award: Best Film | DE | 2016 | Comedy
        Spirited Away | Golden Bear; Oscar: Best Animated Feature | JP | 2001 | Animation
        Bicycle Thieves | Honorary Oscar; BAFTA: Best Film | IT | 1948 | Drama
        The Wages of Fear | Palme d'Or; Golden Bear | FR | 1953 | Thriller
        Gladiator | Oscar: Best Picture | US | 2000 | Action
        Oliver! | Oscar: Best Picture | GB | 1968 | Family
        Wings of Desire | Cannes: Best Director | DE | 1987 | Romance
        Ran | Oscar: Costume Design | JP | 1985 | War
        Rome, Open City | Cannes Grand Prix | IT | 1945 | War
        Forbidden Games | Golden Lion; Honorary Oscar | FR | 1952 | War
        The Silence of the Lambs | Oscar: Best Picture | US | 1991 | Thriller
        A Man for All Seasons | Oscar: Best Picture | GB | 1966 | History
        Seven Samurai | Venice: Silver Lion | JP | 1954 | Action
        The Boy and the Heron | Oscar: Best Animated Feature | JP | 2023 | Animation
        The Garden of the Finzi-Continis | Golden Bear; Oscar: Best Foreign Language Film | IT | 1970 | Drama
        The Silent World | Palme d'Or; Oscar: Best Documentary | FR | 1956 | Documentary
        Platoon | Oscar: Best Picture | US | 1986 | War
        Hamlet | Oscar: Best Picture | GB | 1948 | Drama
        The Ballad of Narayama | Palme d'Or | JP | 1983 | Drama
        Amarcord | Oscar: Best Foreign Language Film | IT | 1973 | Comedy
        The Class | Palme d'Or | FR | 2008 | Drama
        Unforgiven | Oscar: Best Picture | US | 1992 | Western
        Shakespeare in Love | Oscar: Best Picture | GB | 1998 | Romance
        The Eel | Palme d'Or | JP | 1997 | Drama
        Mediterraneo | Oscar: Best Foreign Language Film | IT | 1991 | Comedy
        Indochine | Oscar: Best Foreign Language Film | FR | 1992 | Romance
        Dances with Wolves | Oscar: Best Picture | US | 1990 | Western
        The Third Man | Palme d'Or | GB | 1949 | Mystery
        Godzilla Minus One | Oscar: Best Visual Effects | JP | 2023 | Sci-Fi
        Nights of Cabiria | Oscar: Best Foreign Language Film | IT | 1957 | Drama
        Dheepan | Palme d'Or | FR | 2015 | Crime
        Rain Man | Oscar: Best Picture | US | 1988 | Drama
        Brief Encounter | Cannes Grand Prix | GB | 1945 | Romance
        Il Postino | Oscar: Best Original Score; BAFTA | IT | 1994 | Romance
        Last Year at Marienbad | Golden Lion | FR | 1961 | Mystery
        Braveheart | Oscar: Best Picture | US | 1995 | History
        Blow-Up | Palme d'Or | GB | 1966 | Mystery
        Yesterday, Today and Tomorrow | Oscar: Best Foreign Language Film | IT | 1963 | Comedy
        La Haine | Cannes: Best Director | FR | 1995 | Crime
        American Beauty | Oscar: Best Picture | US | 1999 | Drama
        If.... | Palme d'Or | GB | 1968 | Drama
        The Son's Room | Palme d'Or | IT | 2001 | Drama
        Portrait of a Lady on Fire | Cannes: Best Screenplay | FR | 2019 | Romance
        Chicago | Oscar: Best Picture | US | 2002 | Crime
        The Go-Between | Palme d'Or | GB | 1971 | Romance
        Gomorrah | Cannes Grand Prix; European Film Award: Best Film | IT | 2008 | Crime
        The Lord of the Rings: The Return of the King | Oscar: Best Picture | US | 2003 | Fantasy
        Secrets & Lies | Palme d'Or | GB | 1996 | Drama
        The Battle of Algiers | Golden Lion | IT | 1966 | War
        Million Dollar Baby | Oscar: Best Picture | US | 2004 | Drama
        I, Daniel Blake | Palme d'Or | GB | 2016 | Drama
        Red Desert | Golden Lion | IT | 1964 | Drama
        No Country for Old Men | Oscar: Best Picture | US | 2007 | Crime
        The Full Monty | BAFTA: Best Film | GB | 1997 | Comedy
        Hands over the City | Golden Lion | IT | 1963 | Drama
        The Departed | Oscar: Best Picture | US | 2006 | Crime
        Four Weddings and a Funeral | BAFTA: Best Film | GB | 1994 | Romance
        Shoeshine | Honorary Oscar | IT | 1946 | Drama
        The Hurt Locker | Oscar: Best Picture | US | 2008 | War
        Poor Things | Golden Lion | GB | 2023 | Fantasy
        Rocco and His Brothers | Venice: Special Jury Prize | IT | 1960 | Drama
        Argo | Oscar: Best Picture | US | 2012 | Thriller
        Man on Wire | Oscar: Best Documentary | GB | 2008 | Documentary
        The Working Class Goes to Heaven | Palme d'Or | IT | 1971 | Drama
        12 Years a Slave | Oscar: Best Picture | US | 2013 | History
        The Mattei Affair | Palme d'Or | IT | 1972 | Drama
        Birdman | Oscar: Best Picture | US | 2014 | Comedy
        Perfect Strangers | David di Donatello: Best Film | IT | 2016 | Comedy
        Spotlight | Oscar: Best Picture | US | 2015 | Drama
        Moonlight | Oscar: Best Picture | US | 2016 | Drama
        The Shape of Water | Oscar: Best Picture | US | 2017 | Fantasy
        Green Book | Oscar: Best Picture | US | 2018 | Drama
        Nomadland | Golden Lion; Oscar: Best Picture | US | 2020 | Drama
        CODA | Oscar: Best Picture | US | 2021 | Drama
        Everything Everywhere All at Once | Oscar: Best Picture | US | 2022 | Sci-Fi
        Oppenheimer | Oscar: Best Picture | US | 2023 | History
        Anora | Palme d'Or; Oscar: Best Picture | US | 2024 | Comedy
        Pulp Fiction | Palme d'Or | US | 1994 | Crime
        Taxi Driver | Palme d'Or | US | 1976 | Crime
        Apocalypse Now | Palme d'Or | US | 1979 | War
        Gone with the Wind | Oscar: Best Picture | US | 1939 | Romance
        It Happened One Night | Oscar: Best Picture | US | 1934 | Comedy
        On the Waterfront | Oscar: Best Picture | US | 1954 | Crime
        All About Eve | Oscar: Best Picture | US | 1950 | Drama
        Ben-Hur | Oscar: Best Picture | US | 1959 | History
        West Side Story | Oscar: Best Picture | US | 1961 | Romance
        The Apartment | Oscar: Best Picture | US | 1960 | Comedy
        My Fair Lady | Oscar: Best Picture | US | 1964 | Romance
        The Sound of Music | Oscar: Best Picture | US | 1965 | Family
        Midnight Cowboy | Oscar: Best Picture | US | 1969 | Drama
        The French Connection | Oscar: Best Picture | US | 1971 | Crime
        Patton | Oscar: Best Picture | US | 1970 | War
        Rocky | Oscar: Best Picture | US | 1976 | Drama
        Annie Hall | Oscar: Best Picture | US | 1977 | Comedy
        The Deer Hunter | Oscar: Best Picture | US | 1978 | War
        Kramer vs. Kramer | Oscar: Best Picture | US | 1979 | Drama
        Amadeus | Oscar: Best Picture | US | 1984 | History
        Out of Africa | Oscar: Best Picture | US | 1985 | Romance
        Driving Miss Daisy | Oscar: Best Picture | US | 1989 | Drama
        A Beautiful Mind | Oscar: Best Picture | US | 2001 | Drama
        The Sting | Oscar: Best Picture | US | 1973 | Crime
        Rebecca | Oscar: Best Picture | US | 1940 | Mystery
        Joker | Golden Lion; Oscar: Best Actor | US | 2019 | Crime
        Star Wars | 6 Oscars | US | 1977 | Sci-Fi
        2001: A Space Odyssey | Oscar: Best Visual Effects | US | 1968 | Sci-Fi
        Inception | 4 Oscars | US | 2010 | Sci-Fi
        Interstellar | Oscar: Best Visual Effects | US | 2014 | Sci-Fi
        Dune | 6 Oscars | US | 2021 | Sci-Fi
        The Matrix | 4 Oscars | US | 1999 | Sci-Fi
        Gravity | 7 Oscars | US | 2013 | Sci-Fi
        Get Out | Oscar: Best Original Screenplay | US | 2017 | Horror
        The Exorcist | 2 Oscars | US | 1973 | Horror
        Rosemary's Baby | Oscar: Best Supporting Actress | US | 1968 | Horror
        The Substance | Oscar: Best Makeup | US | 2024 | Horror
        Butch Cassidy and the Sundance Kid | 4 Oscars | US | 1969 | Western
        Django Unchained | 2 Oscars | US | 2012 | Western
        High Noon | 4 Oscars | US | 1952 | Western
        Chinatown | Oscar: Best Original Screenplay | US | 1974 | Mystery
        Citizenfour | Oscar: Best Documentary | US | 2014 | Documentary
        Free Solo | Oscar: Best Documentary | US | 2018 | Documentary
        Fahrenheit 9/11 | Palme d'Or | US | 2004 | Documentary
        Toy Story | Special Achievement Oscar | US | 1995 | Animation
        Coco | Oscar: Best Animated Feature | US | 2017 | Animation
        Inside Out | Oscar: Best Animated Feature | US | 2015 | Animation
        Raiders of the Lost Ark | 4 Oscars | US | 1981 | Adventure
        Jurassic Park | 3 Oscars | US | 1993 | Adventure
        Mary Poppins | 5 Oscars | US | 1964 | Family
        The Wizard of Oz | 2 Oscars | US | 1939 | Family
        Babe | Oscar: Best Visual Effects | AU | 1995 | Family
        M*A*S*H | Palme d'Or | US | 1970 | Comedy
        Barton Fink | Palme d'Or | US | 1991 | Comedy
        The Conversation | Palme d'Or | US | 1974 | Thriller
        Elephant | Palme d'Or | US | 2003 | Drama
        The Tree of Life | Palme d'Or | US | 2011 | Drama
        The Wrestler | Golden Lion | US | 2008 | Drama
        Some Like It Hot | Oscar: Costume Design | US | 1959 | Comedy
        """
}
