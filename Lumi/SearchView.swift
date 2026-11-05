import SwiftUI

func flagEmoji(_ code: String) -> String {
    code.uppercased().unicodeScalars
        .compactMap { UnicodeScalar(127397 + $0.value) }
        .map { String($0) }
        .joined()
}

// Every country in the world (ISO alpha-2)
struct WorldCountry: Identifiable, Hashable {
    let code: String
    var id: String { code }
    var name: String { Locale.current.localizedString(forRegionCode: code) ?? code }
    var flag: String { flagEmoji(code) }

    static let all: [WorldCountry] = Locale.Region.isoRegions
        .map { $0.identifier }
        .filter { $0.count == 2 }
        .map { WorldCountry(code: $0) }
        .sorted { $0.name < $1.name }
}

struct CountryPickerSheet: View {
    let onPick: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var list: [WorldCountry] {
        search.isEmpty ? WorldCountry.all
            : WorldCountry.all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(list) { c in
                Button { onPick(c.code) } label: {
                    Text(verbatim: "\(c.flag)  \(c.name)").foregroundStyle(.black)
                }
            }
            .searchable(text: $search)
            .navigationTitle("Which country is it from?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }
}

// Country list for the filter, with a search bar
struct FilterCountryList: View {
    @Binding var selection: String?
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var list: [WorldCountry] {
        let q = search.trimmingCharacters(in: .whitespaces)
        return q.isEmpty ? WorldCountry.all
            : WorldCountry.all.filter { $0.name.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        List {
            if search.isEmpty {
                Button {
                    selection = nil
                    dismiss()
                } label: {
                    row("Any country", check: selection == nil)
                }
            }

            ForEach(list) { c in
                Button {
                    selection = c.code
                    dismiss()
                } label: {
                    row("\(c.flag)  \(c.name)", check: selection == c.code)
                }
            }

            if list.isEmpty {
                Text("No country found")
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Country")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search a country")
    }

    private func row(_ title: String, check: Bool) -> some View {
        HStack {
            Text(verbatim: title).foregroundStyle(.black)
            Spacer()
            if check { Image(systemName: "checkmark").foregroundStyle(Color.appGreen) }
        }
    }
}

// Filter screen: genre, year and country (one filter for each category)
struct FilterSheet: View {
    let kind: ItemKind
    @Binding var filter: ItemFilter
    @Environment(\.dismiss) private var dismiss

    private let years: [Int] = Array((1900...Calendar.current.component(.year, from: .now)).reversed())

    private var countryHint: String {
        switch kind {
        case .movies: return "Films made in this country."
        case .books: return "Books by authors from this country."
        case .music: return "Landmark songs by artists from this country."
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Genre") {
                    Picker("Genre", selection: $filter.genre) {
                        Text("Any").tag(String?.none)
                        ForEach(APIService.genres(for: kind), id: \.self) { g in
                            Text(verbatim: g).tag(String?.some(g))
                        }
                    }
                }

                Section("Year") {
                    Picker("From", selection: $filter.yearFrom) {
                        Text("Any").tag(Int?.none)
                        ForEach(years, id: \.self) { y in
                            Text(verbatim: String(y)).tag(Int?.some(y))
                        }
                    }
                    Picker("To", selection: $filter.yearTo) {
                        Text("Any").tag(Int?.none)
                        ForEach(years, id: \.self) { y in
                            Text(verbatim: String(y)).tag(Int?.some(y))
                        }
                    }
                }

                Section {
                    NavigationLink {
                        FilterCountryList(selection: $filter.country)
                    } label: {
                        HStack {
                            Text("Country")
                            Spacer()
                            if let code = filter.country {
                                Text(verbatim: "\(WorldCountry(code: code).flag)  \(WorldCountry(code: code).name)")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Any").foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Country")
                } footer: {
                    Text(countryHint)
                }

                Section {
                    Button("Reset filters", role: .destructive) { filter = ItemFilter() }
                        .disabled(!filter.isActive)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Filter \(kind.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            // keep the range valid: "From" is never after "To"
            .onChange(of: filter.yearFrom) { _, new in
                if let a = new, let b = filter.yearTo, a > b { filter.yearTo = a }
            }
            .onChange(of: filter.yearTo) { _, new in
                if let b = new, let a = filter.yearFrom, b < a { filter.yearFrom = b }
            }
        }
        .presentationDetents([.large])
    }
}

// Opened by every "+" and "Change Task" button
struct SearchView: View {
    @Environment(TaskStore.self) private var store
    @State private var kind: ItemKind = .movies
    @State private var filters: [ItemKind: ItemFilter] = [:]   // each category keeps its own filter
    @State private var showFilter = false
    @State private var query = ""
    @State private var results: [Item] = []
    @State private var loading = true
    @State private var selected: Item?
    @State private var art: [String: String] = [:]     // covers found after the list appeared

    private struct Key: Hashable {
        let kind: ItemKind
        let filter: ItemFilter
        let query: String
    }

    private var filter: ItemFilter { filters[kind] ?? ItemFilter() }

    private var filterBinding: Binding<ItemFilter> {
        Binding(get: { filters[kind] ?? ItemFilter() },
                set: { filters[kind] = $0 })
    }

    private var title: String {
        if !query.isEmpty { return "RESULTS" }
        if filter.isActive { return "FILTERED" }
        return kind == .movies ? "AWARD WINNERS" : "ESSENTIALS"
    }

    // "Comedy • 2000–2010 • 🇮🇹 Italy"
    private var summary: String {
        var p: [String] = []
        if let g = filter.genre { p.append(g) }
        switch (filter.yearFrom, filter.yearTo) {
        case let (a?, b?): p.append(a == b ? "\(a)" : "\(a)–\(b)")
        case let (a?, nil): p.append("from \(a)")
        case let (nil, b?): p.append("until \(b)")
        default: break
        }
        if let c = filter.country {
            let w = WorldCountry(code: c)
            p.append("\(w.flag) \(w.name)")
        }
        return p.joined(separator: " • ")
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Category", selection: $kind) {
                ForEach(ItemKind.allCases) { k in Text(k.rawValue).tag(k) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            // What is filtered right now
            if filter.isActive {
                HStack {
                    Text(verbatim: summary)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Button("Clear") { filters[kind] = ItemFilter() }
                        .font(.footnote.weight(.bold))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.appTan.opacity(0.25))
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    Text(title)
                        .font(.headline.weight(.heavy))

                    if !query.isEmpty && filter.isActive {
                        Text("Filters are off while you search. Clear the search to use them.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if loading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else if results.isEmpty {
                        Text("Nothing found. Try another search or other filters.")
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(results) { item in
                            Button {
                                var chosen = item
                                chosen.imageURL = cover(item)
                                selected = chosen
                            } label: { row(item) }
                                .buttonStyle(.plain)
                                .task(id: item.externalID) { await loadArt(item) }
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(kind.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search movies, songs or books")
        .textInputAutocapitalization(.never)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFilter = true } label: {
                    Image(systemName: filter.isActive
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task(id: Key(kind: kind, filter: filter, query: query)) { await load() }
        .sheet(isPresented: $showFilter) {
            FilterSheet(kind: kind, filter: filterBinding)
        }
        .sheet(item: $selected) { item in
            ItemDetailSheet(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(Color.appBackground)
        }
    }

    private func row(_ item: Item) -> some View {
        RowCard(showsChevron: false) {
            PhotoView(name: "", url: cover(item))
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                let sub = [item.author, item.year].filter { !$0.isEmpty }.joined(separator: " · ")
                if !sub.isEmpty {
                    Text(sub)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func cover(_ item: Item) -> String {
        item.imageURL.isEmpty ? (art[item.externalID] ?? "") : item.imageURL
    }

    // Curated songs and books have no cover yet: fetch it when the row appears on screen
    private func loadArt(_ item: Item) async {
        guard item.kind != ItemKind.movies.rawValue, item.imageURL.isEmpty,
              item.externalID.hasPrefix("canon-"), art[item.externalID] == nil else { return }
        let url = await APIService.artwork(forCanonID: item.externalID)
        if !url.isEmpty { art[item.externalID] = url }
    }

    private func load() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            try? await Task.sleep(for: .milliseconds(400))   // wait while the user is typing
            if Task.isCancelled { return }
        }
        loading = true
        let done = Set(store.completedTasks.map { $0.item.externalID })
        let list = q.isEmpty
            ? await APIService.essentials(kind, filter: filter, skipping: done)
            : await APIService.search(kind, query: q)
        if Task.isCancelled { return }
        results = list.filter { !store.isCompleted($0) }
        loading = false
    }
}
