import SwiftUI
@_spi(Experimental) import MapboxMaps // Enables the native SwiftUI Map wrapper

// Simple model to trigger the popup sheet
struct SelectedCountry: Identifiable {
    let id = UUID()
    let name: String
    let isoCode: String     // ISO alpha-2, e.g. "IT"
}

private enum GlobePalette {
    static let land      = UIColor(hex: "FFFFFF") // countries
    static let water     = UIColor(hex: "EEECE7") // seas
    static let space     = UIColor(hex: "FAF9F6") // background:
    static let glow      = UIColor(hex: "ECE8E0") // atmosphere halo, close to globe
    static let glowHigh  = UIColor(hex: "F6F4EF") // atmosphere halo
    static let border    = UIColor(hex: "9A968C") // countries borders
    static let highlight = UIColor(hex: "000000") // selected country

    // Completed countries fade from a pale sage to a deep green
    static let paleGreen = UIColor(hex: "DDEBE3") // 0 tasks (starting point of the fade)
    static let deepGreen = UIColor(hex: "2F5B4A") // 5 tasks or more

    // The more completed tasks, the closer to deepGreen (5 tasks = exactly #2F5B4A)
    static func progressColor(count: Int) -> UIColor {
        let p = CGFloat(min(Double(count) / 5.0, 1))
        let eased = pow(p, 0.7)   // the first tasks already show a visible change
        return blend(paleGreen, deepGreen, eased)
    }

    // Straight blend between two colors: t = 0 gives a, t = 1 gives b
    private static func blend(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return UIColor(red: ar + (br - ar) * t,
                       green: ag + (bg - ag) * t,
                       blue: ab + (bb - ab) * t,
                       alpha: 1.0)
    }
}

private let englishLocale = Locale(identifier: "en")

private extension WorldCountry {
    // Also known by its English name, so "Italy" works when the phone is set to Italian (and the other way round)
    var englishName: String { englishLocale.localizedString(forRegionCode: code) ?? name }

    // Ignores upper/lower case and accents ("cote" finds "Côte d'Ivoire")
    func matches(_ text: String) -> Bool {
        name.localizedStandardContains(text) || englishName.localizedStandardContains(text)
    }

    func startsWith(_ text: String) -> Bool {
        let options: String.CompareOptions = [.anchored, .caseInsensitive, .diacriticInsensitive]
        return name.range(of: text, options: options) != nil
            || englishName.range(of: text, options: options) != nil
    }
}

struct GlobeView: View {
    @Environment(TaskStore.self) private var store
    @State private var selectedCountry: SelectedCountry?
    // Search
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool
    private static let resultRowHeight: CGFloat = 48

    // Every country in the world (the same list used by the task filters), not the old 3-country prototype.
    // Names that START with the text come first: "ita" -> Italy before Mauritania.
    private var matches: [WorldCountry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let found = WorldCountry.all.filter { $0.matches(q) }
        return found.filter { $0.startsWith(q) } + found.filter { !$0.startsWith(q) }
    }

    // Zoom to the country, highlight it and open its tasks panel
    private func select(_ country: WorldCountry, map: MapboxMap?) {
        searchFocused = false
        searchText = ""
        selectedCountry = SelectedCountry(name: country.name, isoCode: country.code)
        if let map { highlightCountry(mapboxMap: map, isoCode: country.code) }
        let target = CountryFocus.target(for: country.code)
        withViewportAnimation(.default(maxDuration: 1.5)) {
            viewport = .camera(center: target.center, zoom: target.zoom)
        }
    }

    private func searchBar(map: MapboxMap?) -> some View {
        let results = matches   // computed once per render (it scans every country)
        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search a country", text: $searchText)
                    .focused($searchFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { if let first = results.first { select(first, map: map) } }
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())

            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(spacing: 0) {
                    if results.isEmpty {
                        Text("No country found")
                            .font(.subheadline)
                            .foregroundStyle(.black)
                            .padding(16)
                    } else {
                        // Fixed row height so the list is as tall as its rows, up to 6 rows, then it scrolls
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(results) { c in
                                    Button { select(c, map: map) } label: {
                                        HStack {
                                            Text(verbatim: "\(c.flag)  \(c.name)")
                                                .font(.body.weight(.semibold))
                                                .foregroundStyle(.black)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: Self.resultRowHeight)
                                    }
                                }
                            }
                        }
                        .frame(height: min(CGFloat(results.count), 6) * Self.resultRowHeight)
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // Set initial camera to view the whole globe
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        zoom: 1.5
    )

    var body: some View {
        MapReader { proxy in
          ZStack(alignment: .top) {
            Map(viewport: $viewport) {
                TapInteraction(.layer("country-fills")) { queriedFeature, context in

                    if case let .string(name)? = queriedFeature.properties["name_en"],
                       case let .string(iso)? = queriedFeature.properties["iso_3166_1"] {

                        // Trigger the popup
                        self.selectedCountry = SelectedCountry(name: name, isoCode: iso)

                        // Highlight the tapped country on the map
                        if let mapboxMap = proxy.map {
                            highlightCountry(mapboxMap: mapboxMap, isoCode: iso)
                        }

                        // Smoothly animate camera to the tapped location
                        withViewportAnimation(.default(maxDuration: 1.2)) {
                            viewport = .camera(center: context.coordinate, zoom: 3.5)
                        }

                        return true // Stops the tap from passing through
                    }

                    return false // Ignores the tap if it didn't find the correct properties
                }
            }
            .mapStyle(.light)
            .onMapLoaded { _ in
                guard let mapboxMap = proxy.map else { return }
                setupCustomGlobe(mapboxMap: mapboxMap)
            }
            .ignoresSafeArea()

            searchBar(map: proxy.map)
          }
        }
        .sheet(item: $selectedCountry) { country in
            CountryPopupView(country: country)
                .presentationDetents([.height(360), .medium])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(360)))
        }
    }

    // MARK: - Completed tasks per country

    private var tasksPerCountry: [String: Int] {
        var counts: [String: Int] = [:]
        for task in store.completedTasks {
            let code = task.item.countryCode
            if !code.isEmpty { counts[code, default: 0] += 1 }
        }
        return counts
    }

    // MARK: - Mapbox Customization & Layer Setup
    private func setupCustomGlobe(mapboxMap: MapboxMap) {
        do {
            // A. Force 3D Globe Projection
            try mapboxMap.setProjection(StyleProjection(name: .globe))

            // B. Customize the Space Background & Atmosphere Halo
            var atmosphere = Atmosphere()
            atmosphere.color = .constant(StyleColor(GlobePalette.glow))
            atmosphere.highColor = .constant(StyleColor(GlobePalette.glowHigh))
            atmosphere.spaceColor = .constant(StyleColor(GlobePalette.space))
            atmosphere.starIntensity = .constant(0.0)
            try mapboxMap.setAtmosphere(atmosphere)

            tintBaseStyle(mapboxMap: mapboxMap)

            // C. Add Mapbox's Built-in Country Boundaries Dataset
            var source = VectorSource(id: "countries-source")
            source.url = "mapbox://mapbox.country-boundaries-v1"
            try mapboxMap.addSource(source)

            // D. One colored layer for every country that has completed tasks
            for (code, count) in tasksPerCountry {
                var progressLayer = FillLayer(id: "country-progress-\(code)", source: "countries-source")
                progressLayer.sourceLayer = "country_boundaries"
                progressLayer.fillColor = .constant(StyleColor(GlobePalette.progressColor(count: count)))
                progressLayer.fillOpacity = .expression(Exp(.switchCase) {
                    Exp(.eq) {
                        Exp(.get) { "iso_3166_1" }
                        code
                    }
                    1.0     // this country
                    0.0     // others
                })
                try mapboxMap.addLayer(progressLayer)
            }

            // E. Invisible fill layer to detect taps and show highlights
            var fillLayer = FillLayer(id: "country-fills", source: "countries-source")
            fillLayer.sourceLayer = "country_boundaries"
            fillLayer.fillColor = .constant(StyleColor(GlobePalette.highlight))
            fillLayer.fillOpacity = .constant(0.0) // Start invisible until tapped
            try mapboxMap.addLayer(fillLayer)

            // F. Stylized country borders
            var lineLayer = LineLayer(id: "country-borders", source: "countries-source")
            lineLayer.sourceLayer = "country_boundaries"
            lineLayer.lineColor = .constant(StyleColor(GlobePalette.border.withAlphaComponent(0.6)))
            lineLayer.lineWidth = .constant(1.0)
            try mapboxMap.addLayer(lineLayer)

        } catch {
            print("Failed to configure Mapbox style: \(error)")
        }
    }

    // MARK: - Base Style Tint

    private func tintBaseStyle(mapboxMap: MapboxMap) {
        do {
            try mapboxMap.updateLayer(withId: "land", type: BackgroundLayer.self) { layer in
                layer.backgroundColor = .constant(StyleColor(GlobePalette.land))
            }
        } catch {
            print("Failed to tint land: \(error)")
        }

        do {
            try mapboxMap.updateLayer(withId: "water", type: FillLayer.self) { layer in
                layer.fillColor = .constant(StyleColor(GlobePalette.water))
            }
        } catch {
            print("Failed to tint water: \(error)")
        }
    }

    // MARK: - Highlight Selected Country
    private func highlightCountry(mapboxMap: MapboxMap, isoCode: String) {
        do {
            try mapboxMap.updateLayer(withId: "country-fills", type: FillLayer.self) { layer in
                let opacityExpression = Exp(.switchCase) {
                    Exp(.eq) {
                        Exp(.get) { "iso_3166_1" }
                        isoCode
                    }
                    0.2 // Opacity for selected country
                    0.0 // Opacity for all other countries
                }
                layer.fillOpacity = .expression(opacityExpression)
            }
        } catch {
            print("Failed to highlight country: \(error)")
        }
    }
}

// MARK: - Popup View
struct CountryPopupView: View {
    let country: SelectedCountry
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var store

    private var done: [CompletedTask] {
        store.completedTasks.filter { $0.item.countryCode == country.isoCode }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(flagEmoji(country.isoCode)) \(country.name)")
                        .font(.title2.bold())
                    Text("\(done.count) completed")
                        .font(.caption)
                        .foregroundStyle(.black)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.gray.opacity(0.6))
                }
            }
            Divider()

            VStack(spacing: 14) {
                ForEach(ItemKind.allCases) { kind in
                    KindProgressRow(kind: kind,
                                    count: done.filter { $0.item.kind == kind.rawValue }.count)
                }
            }

            if done.isEmpty {
                Text("No tasks completed here yet.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(done) { c in
                            Text("• \(c.item.name)")
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(24)
    }
}

struct KindProgressRow: View {
    let kind: ItemKind
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.icon)
                .font(.headline)
                .frame(width: 28)

            Text(kind.rawValue)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text("\(count)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
        }
    }
}

#Preview {
    GlobeView()
        .environment(TaskStore())
}
